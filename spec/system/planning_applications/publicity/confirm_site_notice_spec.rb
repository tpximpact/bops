# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Confirm site notice", js: true do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  let!(:planning_application) do
    create(:planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :published,
      application_type:,
      local_authority: default_local_authority,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com")
  end

  let!(:consultation) { planning_application.consultation }
  let!(:audit) { create(:audit, planning_application:, activity_type: "site_notice_created", audit_comment: "Site notice was emailed to the applicant") }

  before do
    travel_to("2023-01-30")
    create(:site_notice, planning_application:)

    travel_to("2023-02-01")
    sign_in(assessor)

    visit "/planning_applications/#{planning_application.reference}/consultation"
  end

  it "allows planning officer to update displayed at date" do
    click_link "Confirm site notice"

    expect(page).to have_content "Site notice was emailed to the applicant"
    expect(page).to have_content audit.created_at.to_fs(:day_month_year_slashes).to_s

    # Defaults to Time.zone.today if this is not set
    expect(page).to have_field("Day", with: "1")
    expect(page).to have_field("Month", with: "2")
    expect(page).to have_field("Year", with: "2023")

    fill_in "Day", with: ""
    fill_in "Month", with: ""
    fill_in "Year", with: ""
    click_button "Save and mark as complete"
    expect(page).to have_content "Provide the date when the site notice was displayed"

    fill_in "Day", with: "01"
    fill_in "Month", with: "02"
    fill_in "Year", with: "2023"

    click_button "Save and mark as complete"
    expect(page).to have_selector("[role=alert] li", text: "Upload a photo or document of the site notice to continue")

    attach_file("Upload evidence of site notice in place", "spec/fixtures/images/proposed-floorplan.png")
    click_button "Save and mark as complete"
    expect(page).to have_content("Site notice was successfully updated")
    expect(list_item("Confirm site notice")).to have_content("Complete")

    click_link "Confirm site notice"
    expect(page).to have_content("1 February 2023")
    expect(consultation.reload.end_date.to_fs(:day_month_year_slashes)).to eq "22/02/2023"
  end
end
