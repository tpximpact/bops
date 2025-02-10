# spec/controllers/bops_api/v2/public/comments_public_controller_spec.rb

require 'rails_helper'

RSpec.describe BopsApi::V2::Public::CommentsSpecialistController, type: :controller do
  render_views

  let(:local_authority) { create(:local_authority) }
  let(:consultee_responses) do
    create_list(:consultee_response, 3, local_authority:)

  before do
    # Assume authenticated controller and set current_local_authority for testing
    allow_any_instance_of(described_class).to receive(:current_local_authority).and_return(local_authority)
  end

  describe 'GET #show' do
    it 'returns a successful response with paginated results' do
      # Creating sample consultee responses
      consultee_responses

      get :show, params: { format: :json, page: 1, maxresults: 2 }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      expect(json_response["data"].size).to eq(2)
    end

    it 'returns results sorted by received_at in ascending order' do
      create(:consultee_response, received_at: 2.days.ago, local_authority:)
      create(:consultee_response, received_at: 1.day.ago, local_authority:)

      get :show, params: { sort_by: 'received_at', order: 'asc', format: :json }

      json_response = JSON.parse(response.body)
      received_dates = json_response["data"].map { |resp| resp["received_at"].to_date }

      expect(received_dates).to eq(received_dates.reorder("asc"))
    end

    it 'filters based on query parameter' do
      create(:consultee_response, redacted_response: "Specific text", local_authority:)
      create(:consultee_response, redacted_response: "Unrelated", local_authority:)

      get :show, params: { q: 'Specific', format: :json }

      json_response = JSON.parse(response.body)
      responses = json_response["data"]

      expect(responses.size).to eq(1)
      expect(responses.first["redacted_response"]).to include("Specific text")
    end
  end
end
end
