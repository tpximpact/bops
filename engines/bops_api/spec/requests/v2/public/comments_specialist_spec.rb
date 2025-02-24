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

      parameter name: :sort_by, in: :path, schema: {
        type: :string,
        description: "The sort type for the comments"
      }

      parameter name: :order, in: :path, schema: {
        type: :string,
        description: "The order for the comments"
      }

      response "200", "returns a planning application's specialist comments given a reference" do
        example "application/json", :default, example_fixture("comments.json")
        schema "$ref" => "#/components/schemas/Comments"

        let(:reference) { planning_application.reference }
        let(:sort_by) { 'received_at' }
        let(:order) { 'desc' }

        run_test! do |response|
          data = JSON.parse(response.body)
          puts data.inspect
          expect(data["metadata"]["totalResults"]).to eq(2)
          expect(data["data"].count).to eq(2)
        end

      end

    end
  end
end