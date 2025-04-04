# frozen_string_literal: true

module PlanningDataHelper
  BASE_URL = "https://www.planning.data.gov.uk"

  def stub_planning_data_api_request_for(reference)
    stub_request(:get, "#{BASE_URL}/entity.json?reference=#{reference}&dataset=local-authority")
  end

  def planning_data_api_response(status, body = "LBH")
    status = Rack::Utils.status_code(status)

    body = Rails.root.join("spec", "fixtures", "planning_data", "#{body}.json").read

    {status:, body:}
  end

  def stub_any_planning_data_entity_geojson_request
    stub_request(:get, "#{BASE_URL}/entity/.geojson")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: "{}"
      )
  end

  def stub_planning_data_entity_request(id)
    stub_request(:get, "#{BASE_URL}/entity/#{id}.json")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: file_fixture("entities/#{id}.json").read
      )
  end

  def stub_planning_data_entity_geojson_request(id)
    stub_request(:get, "#{BASE_URL}/entity/#{id}.geojson")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/geojson"},
        body: file_fixture("entities/#{id}.geojson").read
      )
  end

  def planning_data_entity_geojson_response(status, body = "1000005")
    status = Rack::Utils.status_code(status)

    body = Rails.root.join("spec", "fixtures", "files", "entities", "#{body}.json").read

    {status:, body:}
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(PlanningDataHelper)

    config.before do
      stub_planning_data_api_request_for("BUC").to_return(planning_data_api_response(:ok, "BUC"))
      stub_planning_data_api_request_for("LBH").to_return(planning_data_api_response(:ok, "LBH"))
      stub_planning_data_api_request_for("SWK").to_return(planning_data_api_response(:ok, "SWK"))
      stub_planning_data_api_request_for("TEST").to_return(planning_data_api_response(:ok, "TEST"))
      stub_planning_data_entity_geojson_request("1000005").to_return(planning_data_entity_geojson_response(:ok, "1000005"))
    end
  end
end
