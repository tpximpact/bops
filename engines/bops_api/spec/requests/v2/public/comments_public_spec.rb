# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:document) { create(:document, :with_tags, validated: true, publishable: true) }

  path "/api/v2/public/planning_applications/{reference}/comments/public" do
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

      response "200", "returns a planning application's public comments given a reference" do
        example "application/json", :default, example_fixture("public/comments_public.json")
        schema "$ref" => "#/components/schemas/CommentsPublicResponse"
        let(:reference) { planning_application.reference }
        let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
        before do
          create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
          create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
        end

        let(:page) { 1 }
        let(:sortBy) { "receivedAt" }
        let(:orderBy) { "desc" }
        let(:resultsPerPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["pagination"]["totalItems"]).to eq(2)
          expect(data["pagination"]["currentPage"]).to eq(1)
          expect(data["pagination"]["resultsPerPage"]).to eq(2)
          expect(data["summary"]["totalComments"]).to eq(2)
          sort_field = (sortBy == "receivedAt") ? "receivedAt" : "id"
          sorted_values = data["comments"].pluck(sort_field)

          expected_order = (orderBy == "asc") ? sorted_values.sort : sorted_values.sort.reverse
          expect(sorted_values).to eq(expected_order)
        end
      end

        response "200", "returns a planning application's public comments filtering by sortBy" do
          example "application/json", :default, example_fixture("public/comments_public.json")
          schema "$ref" => "#/components/schemas/CommentsPublicResponse"
          let(:reference) { planning_application.reference }
          let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
          before do
            create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
            create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
          end

          let(:sortBy) { "id" }
          let(:orderBy) { "desc" }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["pagination"]["totalItems"]).to eq(2)
            expect(data["pagination"]["currentPage"]).to eq(1)
            expect(data["pagination"]["resultsPerPage"]).to eq(10)
            expect(data["summary"]["totalComments"]).to eq(2)
            sort_field = (sortBy == "receivedAt") ? "receivedAt" : "id"
            sorted_values = data["comments"].pluck(sort_field)

            expected_order = (orderBy == "asc") ? sorted_values.sort : sorted_values.sort.reverse
            expect(sorted_values).to eq(expected_order)
          end
        end

        response "200", "returns a planning application's public comments filtering by orderBy" do
          example "application/json", :default, example_fixture("public/comments_public.json")
          schema "$ref" => "#/components/schemas/CommentsPublicResponse"
          let(:reference) { planning_application.reference }
          let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
          before do
            create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
            create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
          end

          let(:sortBy) { "receivedAt" }
          let(:orderBy) { "asc" }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["pagination"]["totalItems"]).to eq(2)
            expect(data["pagination"]["currentPage"]).to eq(1)
            expect(data["pagination"]["resultsPerPage"]).to eq(10)
            expect(data["summary"]["totalComments"]).to eq(2)
            sort_field = (sortBy == "receivedAt") ? "receivedAt" : "id"
            sorted_values = data["comments"].pluck(sort_field)

            expected_order = (orderBy == "asc") ? sorted_values.sort : sorted_values.sort.reverse
            expect(sorted_values).to eq(expected_order)
          end
        end

      response "200", "returns a planning application's public comments filtering by query" do
        example "application/json", :default, example_fixture("public/comments_public.json")
        schema "$ref" => "#/components/schemas/CommentsPublicResponse"
        let(:reference) { planning_application.reference }
        let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
        before do
          create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
        end

        let(:query) { "like" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["pagination"]["totalItems"]).to eq(1)
          expect(data["pagination"]["currentPage"]).to eq(1)
          expect(data["pagination"]["resultsPerPage"]).to eq(10)
          expect(data["summary"]["totalComments"]).to eq(1)
          expect(data["comments"].first["comment"]).to include("I like it")
        end
      end

      it "validates successfully against the example comments_public json" do
        resolved_schema = load_and_resolve_schema(name: "comments_public", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("public/comments_public.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end
    end
  end
end
