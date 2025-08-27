# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::PlanningData::Query do
  let(:query) { described_class.new }

  describe "#get_council_code" do
    context "when the request is successful" do
      context "when a valid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("BUC").to_return(planning_data_api_response(:ok, "BUC"))
          stub_planning_data_api_request_for("LBH").to_return(planning_data_api_response(:ok, "LBH"))
          stub_planning_data_api_request_for("SWK").to_return(planning_data_api_response(:ok, "SWK"))
        end

        it "returns buckinghamshire council's reference code" do
          expect(query.get_council_code("BUC")).to eq("BUC")
        end

        it "returns lambeth council's reference code" do
          expect(query.get_council_code("LBH")).to eq("LBH")
        end

        it "returns southwark council's reference code" do
          expect(query.get_council_code("SWK")).to eq("SWK")
        end
      end

      context "when an invalid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("TEST").to_return(planning_data_api_response(:ok, "TEST"))
        end

        it "returns nil" do
          expect(query.get_council_code("TEST")).to be_nil
        end
      end
    end
  end

  describe "#get_entity" do
    let(:submission) { JSON.parse(file_fixture("entities/1000005.geojson").read, symbolize_names: true) }

    context "when the request is successful" do
      context "when a valid entity reference is supplied" do
        before do
          stub_planning_data_entity_geojson_request("1000005").to_return(planning_data_entity_geojson_response(:ok, "1000005"))
        end

        it "returns entity's data" do
          expect(query.get_entity_geojson("1000005")).to eq(submission)
        end
      end
    end
  end
end
