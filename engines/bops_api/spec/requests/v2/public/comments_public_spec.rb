# # spec/controllers/bops_api/v2/public/comments_public_controller_spec.rb

# require 'rails_helper'

# RSpec.describe BopsApi::V2::Public::CommentsPublicController, type: :controller do
#   render_views

#   let(:local_authority) { create(:local_authority) }
#   let(:neighbour_responses) do
#     create_list(:neighbour_response, 3, local_authority:)


#   before do
#     # Assume authenticated controller and set current_local_authority for testing
#     allow_any_instance_of(described_class).to receive(:current_local_authority).and_return(local_authority)
#   end

#   describe 'GET #show' do
#     it 'returns a successful response with paginated results' do
#       # Creating sample neighbour responses
#       neighbour_responses

#       get :show, params: { format: :json, page: 1, maxresults: 2 }

#       expect(response).to have_http_status(:success)
#       json_response = JSON.parse(response.body)
      
#       expect(json_response["data"].size).to eq(2)
#     end

#     it 'returns results sorted by received_at in ascending order' do
#       create(:neighbour_response, received_at: 2.days.ago, local_authority:)
#       create(:neighbour_response, received_at: 1.day.ago, local_authority:)

#       get :show, params: { sort_by: 'received_at', order: 'asc', format: :json }

#       json_response = JSON.parse(response.body)
#       received_dates = json_response["data"].map { |resp| resp["received_at"].to_date }

#       expect(received_dates).to eq(received_dates.sort)
#     end

#     it 'filters based on query parameter' do
#       create(:neighbour_response, redacted_response: "Specific text", local_authority:)
#       create(:neighbour_response, redacted_response: "Unrelated", local_authority:)

#       get :show, params: { q: 'Specific', format: :json }

#       json_response = JSON.parse(response.body)
#       responses = json_response["data"]

#       expect(responses.size).to eq(1)
#       expect(responses.first["redacted_response"]).to include("Specific")
#     end
#   end
# end
# end

# frozen_string_literal: true

# require "swagger_helper"

# RSpec.describe "BOPS public API" do
#   let(:local_authority) { create(:local_authority, :default) }
#   let(:page) { 1 }
#   let(:maxresults) { 5 }
  # let(:application_type) { create(:application_type, :householder) }
  # let(:neighbour_responses) { create(:id, :redacted_response, :received_at, :summary_tag) }
  # let(:page) { 1 }
  # let(:maxresults) { 2 }
  # let(:q) { "test" }
  # let(:order) { "asc" }
  # let(:sort_by) { "id" }
  # let(:token) { "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
  # let!(:api_user) { create(:api_user, token:, local_authority:) }
  # let!(:Authorization) { "Bearer #{token}" }

  # around do |example|
  #   travel_to("2024-10-22T10:30:00Z") { example.run }
  # end
  # before do
  #   create_list(
  #     :neighbour_response,
  #     6,
  #     redacted_response: "This is a test response",
  #     received_at: Time.zone.now
  #   )
  # end
  #   before do
  #   create_list(:id, 1, :redacted_response, "Any text", :received_at, 1.day.ago , :summary_tag, "happy")
  #   create_list(:id, 2, :redacted_response, "Submmited", :received_at, 2.day.ago , :summary_tag, "happy")
  # end

  # path "/api/v2/public/planning_applications/{reference}/comments" do
  #   get "Retrieves comments based on a search criteria" do
  #     tags "Comments"
  #     produces "application/json"

  #     parameter name: :reference, in: :path, schema: {
  #       type: :string,
  #       description: "The planning application reference"
  #     }, required: true

  #     parameter name: :page, in: :query, schema: {
  #       type: :integer,
  #       default: 1
  #     }, required: false

  #     parameter name: :maxresults, in: :query, schema: {
  #       type: :integer,
  #       default: 10
  #     }, required: false

  #     parameter name: "q", in: :query, schema: {
  #       type: :string,
  #       description: "Search by redacted response content"
  #     }, required: false

  #     parameter name: :sort_by, in: :query, schema: {
  #       type: :string,
  #       enum: ["received_at"],
  #       description: "Field to sort the comments by"
  #     }, required: false

  #     parameter name: :order, in: :query, schema: {
  #       type: :string,
  #       enum: ["asc", "desc"],
  #       description: "Sort order for the comments"
  #     }, required: false

      # parameter name: :page, in: :query, schema: {
      #   type: :integer,
      #   default: 1
      # }, required: false

      # parameter name: :maxresults, in: :query, schema: {
      #   type: :integer,
      #   default: 2
      # }, required: false

      # parameter name: "q", in: :query, schema: {
      #   type: :string,
      #   description: "Search by reference or description"
      # }, required: false


      # parameter name: "sort_by", in: :query, schema: {
      #   type: :string,
      #   default: "received_at"
      # }, required: false


      # parameter name: "order", in: :query, schema: {
      #   type: :string,
      #   default: "desc"
      # }, required: false

      # response "200", "returns comments sorted and paginated" do
        # example "application/json", :default, example_fixture("neighbourResponses.json")
        # schema "$ref" => "#/components/schemas/NeighbourResponses"

        # let(:page) { 1 }
        # let(:q) { neighbour_responses.first.id }
        # let(:reference) { planning_application.reference }
        # let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
        # before do
        #   create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
        # end

        # let(:page) { 1 }
        # let(:reference) { "valid_reference" }

        # run_test! do |response|
        #   data = JSON.parse(response.body)
        #   metadata = data["metadata"]
        #   # Rails.logger.info "Final SQL Query: #{metadata}"
        #          print "Final SQL Query: #{metadata}"

        #   expect(metadata).to eq(
        #     {
        #       "page" => 1,
        #       "results" => 5,
        #       "from" => 1,
        #       "to" => 5,
        #       "total_pages" => 2,
        #       "total_results" => 6
        #     }
        #   )

          # expect(data["data"].first["id"]).to eq("PlanX-#{neighbour_responses.first.id}")
      #   end
      # end

      # it "validates successfully against the example neighbour responses json" do
      #   resolved_schema = load_and_resolve_schema(name: "neighbourResponses", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
      #   schemer = JSONSchemer.schema(resolved_schema)
      #   example_json = example_fixture("neighbourResponses.json")

      #   expect(schemer.valid?(example_json)).to eq(true)
      # end
#     end
#   end
# end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Comment::QueryPublicService do
  let(:scope) { CommentsPublic.all }
  let(:params) { {} }
  let(:service) { described_class.new(scope, params) }
  let(:pagy_and_results) { service.call }
  let(:pagy) { pagy_and_results.first }
  let(:results) { pagy_and_results.last }

  describe "call" do
    context "when page and maxresults are provided" do
      before do
        create_list(:comments_public, 25)
      end

      let(:params) { {page: 2, maxresults: 5} }

      it "paginates the results correctly" do
        expect(pagy).to have_attributes(
          page: 2,
          items: 5,
          count: 25,
          pages: 5,
          from: 6,
          to: 10
        )
      end

      context "when exceeding the maxresults limit" do
        let(:params) { {maxresults: 50} }

        it "limits the results to MAXRESULTS_LIMIT" do
          expect(pagy.items).to eq(BopsApi::Pagination::MAXRESULTS_LIMIT)
        end
      end
    end

    # context "when performing a search" do
    #   let!(:matching_reference) { create(:planning_application) }
    #   let!(:matching_description) { create(:planning_application, description: "This is a unique description") }
    #   let!(:matching_address) { create(:planning_application, address_1: "123 Unique Road", county: "Greater London", town: "Unique Town", postcode: "SE21 7DN") }

    #   context "when searching by reference" do
    #     let(:params) { {q: matching_reference.reference} }

    #     it "returns applications matching the reference" do
    #       expect(results).to include(matching_reference)
    #       expect(results).not_to include(matching_description, matching_address)
    #     end
    #   end

    #   context "when searching by description" do
    #     let(:params) { {q: "unique description"} }

    #     it "returns applications matching the description" do
    #       expect(results).to include(matching_description)
    #       expect(results).not_to include(matching_reference, matching_address)
    #     end
    #   end

    #   context "when searching by address" do
    #     context "with address lines" do
    #       let(:params) { {q: "123 unique Road Unique town"} }

    #       it "returns applications matching the address" do
    #         expect(results).to include(matching_address)
    #         expect(results).not_to include(matching_reference, matching_description)
    #       end
    #     end

    #     context "with postcode" do
    #       context "with exact postcode query" do
    #         let(:params) { {q: "SE21 7DN"} }

    #         it "returns applications matching the postcode" do
    #           expect(results).to include(matching_address)
    #           expect(results).not_to include(matching_reference, matching_description)
    #         end
    #       end

    #       context "with postcode query" do
    #         let(:params) { {q: "se217Dn"} }

    #         it "returns applications matching the postcode" do
    #           expect(results).to include(matching_address)
    #           expect(results).not_to include(matching_reference, matching_description)
    #         end
    #       end
    #     end
    #   end

    #   context "when no search term matches" do
    #     let(:params) { {q: "noresults"} }

    #     it "returns no results" do
    #       expect(results).to be_empty
    #     end
    #   end
    # end
  end
end
