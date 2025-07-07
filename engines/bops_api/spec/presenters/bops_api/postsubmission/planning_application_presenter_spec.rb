require "rails_helper"

RSpec.describe BopsApi::Postsubmission::PlanningApplicationPresenter do
    let(:local_authority) { create(:local_authority, :default) }
    let(:application_type) { create(:application_type, :householder) }



    let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, :with_press_notice, local_authority:, application_type:, user: create(:user)) }


    let(:submission) { JSON.parse(BopsApi::Engine.root.join("spec", "fixtures", "examples", "odp", "v0.7.5", "application", "planningPermission", "fullHouseholder.json").read) }
    let(:planx_planning_data) { create(:planx_planning_data, params_v2: submission) }
    let(:planning_application_with_submission) { create(:planning_application, local_authority:, planx_planning_data:) }
    
    subject(:presenter) { described_class.new(planning_application) }

    describe "planning application" do
    
      it "returns the application type code" do
        puts planning_application.inspect
        puts planning_application_with_submission.inspect
        expect(presenter.applicationType).to eq "pp.full.householder"
      end

    end


    # subject(:presenter) { described_class.new(planning_application) }

    # describe "#applicationType" do
    #   it "returns the application type code" do
    #     expect(presenter.applicationType).to eq "pp.full.householder"
    #   end
    # end

    # describe "#metadata" do
    #   it "returns a Metadata object" do
    #     expect(presenter.metadata).to be_a described_class::Metadata
    #   end

      # it "returns correct metadata fields" do
      #   metadata = presenter.metadata
      #   expect(metadata.organisation).to eq "TODO"
      #   expect(metadata.id).to eq planning_application.application_type&.code
      #   expect(metadata.schema).to include("postSubmissionApplication.json")
      #   expect(metadata.submittedAt).to eq planning_application.received_at
      #   expect(metadata.generatedAt).to be_a(Time)
      # end

    #   it "returns correct as_json structure" do
    #     json = presenter.metadata.as_json
    #     expect(json[:organisation]).to eq "TODO"
    #     expect(json[:id]).to eq planning_application.reference
    #     expect(json[:schema]).to include("postSubmissionApplication.json")
    #     expect(json[:submittedAt]).to be_a(String)
    #     expect(json[:generatedAt]).to be_a(String)
    #   end
    # end

    # describe "#as_json" do
    #   it "returns the expected hash" do
    #     json = presenter.as_json
    #     expect(json[:generatedFrom]).to eq "presenter"
    #     expect(json[:applicationType]).to eq "pp.full.householder"
    #     expect(json[:metadata]).to be_a(Hash)
    #     expect(json[:metadata][:id]).to eq planning_application.reference
    #   end
    # end

end