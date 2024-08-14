# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a planning application via the API", show_exceptions: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority: default_local_authority) }
  let!(:planning_application) { create(:planning_application, :planning_permission, local_authority: default_local_authority) }

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.reference}/neighbour_responses"
  end

  let(:headers) do
    {"CONTENT-TYPE": "application/json",
     Authorization: "Bearer #{api_user.token}"}
  end

  it "successfully creates a new neighbour response" do
    json = {
      name: "Keira Walsh",
      response: "This is good",
      address: "123 street, AAA111",
      summary_tag: "supportive",
      files: [""]
    }.to_json

    post(path, params: json, headers:)

    expect(response).to be_successful
  end

  it "captures errors successfully" do
    json = {
      name: "",
      response: "",
      files: [""]
    }.to_json

    post(path, params: json, headers:)

    expect(response).not_to be_successful
    expect(response).to have_http_status :bad_request
  end
end
