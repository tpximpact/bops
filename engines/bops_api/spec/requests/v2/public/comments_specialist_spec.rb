# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create(
      :planning_application,
      :published,
      :in_assessment,
      :with_boundary_geojson,
      :planning_permission,
      local_authority:
    )
  end

  let!(:consultation) do
    planning_application.consultation
  end

  let!(:alice_smith) do
      create(:consultee, :internal, :with_response, name: "Alice Smith", consultation:)
  end

  let!(:bella_jones) do
    create(:consultee, :external, :with_response, name: "Bella Jones", consultation:)
  end

  path "/api/v2/public/planning_applications/{reference}/comments/specialist" do
    get "Retrieves comments for a planning application" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      parameter name: :sortBy, in: :query, schema: {
        type: :string,
        enum: ["id", "receivedAt"],
        default: "receivedAt",
        description: "The sort type for the comments"
      }, required: false

      parameter name: :orderBy, in: :query, schema: {
        type: :string,
        enum: ["asc", "desc"],
        default: "desc",
        description: "The order for the comments"
      }, required: false

      parameter name: :resultsPerPage, in: :query, schema: {
        type: :integer,
        default: 10,
        description: "Max result for page"
      }, required: false

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :query, in: :query, schema: {
        type: :string,
        description: "Search by redacted comment content"
      }, required: false

      response "200", "returns a planning application's specialist comments given a reference" do
        example "application/json", :default, example_fixture("public/comments_specialist.json")
        schema "$ref" => "#/components/schemas/CommentsSpecialistResponse"

        let(:reference) { planning_application.reference }
        let(:sortBy) { "receivedAt" }
        let(:orderBy) { "desc" }
        let(:page) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["pagination"]["resultsPerPage"]).to eq(10)
          expect(data["pagination"]["currentPage"]).to eq(1)
          expect(data["pagination"]["totalPages"]).to eq(1)
          expect(data["pagination"]["totalItems"]).to eq(2)
          expect(data["summary"]["totalComments"]).to eq(2)
          expect(data["summary"]["sentiment"]["supportive"]).to eq(2)
        end
      end

      response "200", "returns a planning application's specialist comments filtering by sortBy" do
        example "application/json", :default, example_fixture("public/comments_specialist.json")
        schema "$ref" => "#/components/schemas/CommentsSpecialistResponse"

        let(:reference) { planning_application.reference }
        let(:sortBy) { "id" }
        let(:orderBy) { "desc" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["pagination"]["resultsPerPage"]).to eq(10)
          expect(data["pagination"]["currentPage"]).to eq(1)
          expect(data["pagination"]["totalPages"]).to eq(1)
          expect(data["pagination"]["totalItems"]).to eq(2)
          expect(data["summary"]["totalComments"]).to eq(2)
          sort_field = (sortBy == "receivedAt") ? "received_at" : "id"
          sorted_comments = data["comments"].sort_by { |c| c[sort_field] }
          sorted_comments.reverse! if orderBy == "desc"
          expect(data["comments"]).to eq(sorted_comments)
        end
      end

      response "200", "returns a planning application's specialist comments filtering by orderBy" do
        example "application/json", :default, example_fixture("public/comments_specialist.json")
        schema "$ref" => "#/components/schemas/CommentsSpecialistResponse"

        let(:reference) { planning_application.reference }
        let(:sortBy) { "receivedAt" }
        let(:orderBy) { "asc" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["pagination"]["resultsPerPage"]).to eq(10)
          expect(data["pagination"]["currentPage"]).to eq(1)
          expect(data["pagination"]["totalPages"]).to eq(1)
          expect(data["pagination"]["totalItems"]).to eq(2)
          expect(data["summary"]["totalComments"]).to eq(2)
          sort_field = (sortBy == "receivedAt") ? "receivedAt" : "id"
          sorted_values = data["comments"].pluck(sort_field)
          expected_order = (orderBy == "asc") ? sorted_values.sort : sorted_values.sort.reverse
          expect(sorted_values).to eq(expected_order)
        end
      end

       response "200", "returns a planning application's specialist comments filtering by query" do
         example "application/json", :default, example_fixture("public/comments_specialist.json")
         schema "$ref" => "#/components/schemas/CommentsSpecialistResponse"
         let(:reference) { planning_application.reference }

         let(:query) { "like" }

         run_test! do |response|
           data = JSON.parse(response.body)
           expect(data["pagination"]["totalItems"]).to eq(2)
           expect(data["pagination"]["currentPage"]).to eq(1)
           expect(data["pagination"]["resultsPerPage"]).to eq(10)
           expect(data["summary"]["totalComments"]).to eq(2)
           expect(data["comments"].first["comment"]).to include("I like it")
         end
       end

      response "404", "does not return comments for unpublished planning applications" do
        let!(:unpublished_planning_application) do
          create(:planning_application, :in_assessment, local_authority:)
        end

        let(:reference) { unpublished_planning_application.reference }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["error"]["message"]).to eq("Not Found")
        end
      end

      it "validates successfully against the example comments_specialist json" do
        resolved_schema = load_and_resolve_schema(name: "comments_specialist", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("public/comments_specialist.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end
    end
  end
end
