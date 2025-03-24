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
  consultee = create(:consultee, :internal, name: "Alice Smith", consultation:)
  response = create(:consultee_response, consultee: consultee)
  puts "Created consultee: #{consultee.inspect}"
  puts "Created response: #{response.inspect}"
  consultee
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
        default: "received_at",
        description: "The sort type for the comments"
      }, required: false

      parameter name: :order, in: :query, schema: {
        type: :string,
        default: "asc",
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

      response "200", "returns a planning application's specialist comments given a reference" do
        example "application/json", :default, example_fixture("public/comments.json")
        schema "$ref" => "#/components/schemas/Comments"

        let(:reference) { planning_application.reference }
        let(:sortBy) { 'received_at' }
        let(:order) { 'desc' }
        let(:page) { 1 }


        run_test! do |response|
          data = JSON.parse(response.body)
          puts data.inspect
          expect(data["pagination"]["resultsPerPage"]).to eq(10)
          expect(data["pagination"]["currentPage"]).to eq(1)
          expect(data["pagination"]["totalPages"]).to eq(1)
          expect(data["pagination"]["totalItems"]).to eq(0)
          expect(data["summary"]["totalComments"]).to eq(0)
        end

      end
      response "200", "returns a planning application's specialist comments given a reference sortBy id and orderBy asc" do
        example "application/json", :default, example_fixture("public/comments.json")
        schema "$ref" => "#/components/schemas/Comments"

        let(:reference) { planning_application.reference }
        let(:sortBy) { 'id' }
        let(:order) { 'asc' }
        let(:page) { 1 }
        let(:query) { '' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["pagination"]["resultsPerPage"]).to eq(10)
          expect(data["pagination"]["totalPages"]).to eq(1)
          expect(data["pagination"]["totalPages"]).to eq(1)
          expect(data["pagination"]["totalItems"]).to eq(0)
          expect(data["summary"]["totalComments"]).to eq(0)
        end

      end

    end
  end
end