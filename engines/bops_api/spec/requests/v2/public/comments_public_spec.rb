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
        let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
        before do
          create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
        end

        let(:sort_by) { 'received_at' }
        let(:order) { 'desc' }

        run_test! do |response|
          data = JSON.parse(response.body)
          puts data.inspect
          expect(data["metadata"]["totalResults"]).to eq(1)
          expect(data["data"].count).to eq(1)
        end

      end

    end
  end
end