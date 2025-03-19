# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::V2::Public::CommentsPublicController, type: :controller do
  let!(:southwark) { create(:local_authority, :southwark) }
  let!(:planning_application) { create(:planning_application, :planning_permission, :assessment_in_progress, :consulting, :published, local_authority: southwark) }
  let!(:consultation) { Consultation.find_or_create_by(planning_application:) }

  let!(:neighbour1) { create(:neighbour, source: "sent_comment", consultation:) }
  let!(:neighbour2) { create(:neighbour, source: "sent_comment", consultation:) }
  let!(:neighbour3) { create(:neighbour, source: "sent_comment", consultation:) }

  let!(:neighbour_responses1) { create(:neighbour_response, summary_tag: "supportive", neighbour: neighbour1) }
  let!(:neighbour_responses2) { create(:neighbour_response, summary_tag: "neutral", neighbour: neighbour1) }
  let!(:neighbour_responses3) { create(:neighbour_response, summary_tag: "objection", neighbour: neighbour1) }
  let!(:neighbour_responses) { create_list(:neighbour_response, 5, neighbour: neighbour2) }
  let!(:neighbour_responses) { create_list(:neighbour_response, 2, neighbour: neighbour3) }

  routes { BopsApi::Engine.routes }

  before do
    token = "bops_pDzTZPTrC7HiBiJHGEJVUSkX2PVwkk1d4mcTm9PgnQ"
    create(:api_user, token:, local_authority: southwark)

    request.set_header("HTTP_HOST", "southwark.bops.test")
    request.set_header("HTTP_AUTHORIZATION", "Bearer #{token}")

    request.set_header("bops.local_authority", southwark)
    request.set_header("bops.user_scope", southwark.users.kept)

    allow_any_instance_of(BopsApi::V2::Public::CommentsPublicController)
      .to receive(:find_planning_application).and_return(planning_application)

    allow(planning_application).to receive(:consultation).and_return(consultation)

    # Mock neighbour_responses to return an ActiveRecord relation
    allow(consultation).to receive(:neighbour_responses).and_return(NeighbourResponse.all)

    # Ensure the redacted scope is applied
    allow(NeighbourResponse).to receive(:redacted).and_return(NeighbourResponse.all)
  end

  describe "GET #index" do
    let(:json_response) { JSON.parse(response.body) }

    context "when the request is valid" do
      it "returns a successful response" do
        get :index, params: {planning_application_id: planning_application.id, format: :json}

        # puts "Request URL: #{request.url}"
        # puts "Request Path: #{request.path}"
        # puts "Response Body: #{response.body}"
        # puts request.inspect
        # puts response.body
        # # puts json_response.inspect

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns the correct JSON structure" do
        get :index, params: {planning_application_id: planning_application.id, format: :json}

        puts "Request URL: #{request.url}"
        puts "Request Path: #{request.path}"
        puts "Response Body: #{response.body}"
        puts response.body.inspect

        expect(json_response).to include("comments", "pagination", "summary")
        expect(json_response["comments"]).to be_an(Array)
        expect(json_response["pagination"]).to include("current_page", "total_pages", "total_count")
        expect(json_response["summary"]).to include("supportive", "objection", "neutral")
      end
    end

    context "when there are no neighbour responses" do
      before do
        allow(consultation).to receive(:neighbour_responses).and_return(NeighbourResponse.none)
      end

      it "returns an empty comments array" do
        get :index, params: {planning_application_id: planning_application.id, format: :json}
        expect(json_response["comments"]).to eq([])
        expect(json_response["pagination"]["total_count"]).to eq(0)
      end
    end

    context "when the consultation is not found" do
      before do
        allow(planning_application).to receive(:consultation).and_return(nil)
      end

      it "returns a 404 error" do
        get :index, params: {planning_application_id: planning_application.id, format: :json}
        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("Consultation not found")
      end
    end

    context "when the planning application is not found" do
      before do
        allow_any_instance_of(BopsApi::V2::Public::CommentsPublicController)
          .to receive(:find_planning_application).and_return(nil)
      end

      it "returns a 404 error" do
        get :index, params: {planning_application_id: 999, format: :json}
        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("Planning application not found")
      end
    end

    context "when pagination parameters are provided" do
      it "paginates the results correctly" do
        get :index, params: {planning_application_id: planning_application.id, resultsPerPage: 2, page: 1, format: :json}

        expect(json_response["comments"].size).to eq(2)
        expect(json_response["pagination"]["current_page"]).to eq(1)
        expect(json_response["pagination"]["total_pages"]).to eq(3) # Assuming 5 responses and 2 per page
      end
    end

    context "when invalid pagination parameters are provided" do
      it "defaults to the first page and default results per page" do
        get :index, params: {planning_application_id: planning_application.id, resultsPerPage: -1, page: -1, format: :json}

        expect(json_response["pagination"]["current_page"]).to eq(1)
        expect(json_response["pagination"]["total_pages"]).to eq(1) # Assuming default resultsPerPage is greater than 5
      end
    end

    context "when invalid parameters are provided" do
      it "returns a 400 error for invalid sortBy" do
        get :index, params: {planning_application_id: planning_application.id, sortBy: "invalidField", format: :json}
        expect(response).to have_http_status(:bad_request)
        expect(json_response["error"]).to include("Invalid sortBy field")
      end

      it "returns a 400 error for invalid orderBy" do
        get :index, params: {planning_application_id: planning_application.id, orderBy: "invalidOrder", format: :json}
        expect(response).to have_http_status(:bad_request)
        expect(json_response["error"]).to include("Invalid orderBy value")
      end
    end
  end
end
