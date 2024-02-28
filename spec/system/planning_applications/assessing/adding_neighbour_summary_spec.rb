# frozen_string_literal: true

require "rails_helper"

RSpec.describe "neighbour responses" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:application_type) { create(:application_type, :prior_approval) }
  let!(:planning_application) do
    create(:planning_application, :in_assessment, :from_planx_immunity, application_type:,
      local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
  end

  context "when planning application is in assessment" do
    let!(:consultation) { planning_application.consultation }
    let!(:neighbour1) { create(:neighbour, address: "1, Test Lane, AAA111", consultation:) }
    let!(:neighbour2) { create(:neighbour, address: "2, Test Lane, AAA111", consultation:) }
    let!(:neighbour3) { create(:neighbour, address: "3, Test Lane, AAA111", consultation:) }
    let!(:objection_response) { create(:neighbour_response, neighbour: neighbour1, summary_tag: "objection", tags: ["design", "disabled_access"]) }
    let!(:supportive_response1) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive", tags: ["design"]) }
    let!(:supportive_response2) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive", tags: ["disabled_access"]) }
    let!(:neutral_response) { create(:neighbour_response, neighbour: neighbour2, summary_tag: "neutral") }

    it "I can view the information on the neighbour responses page" do
      click_link "Check and assess"

      within("#assessment-information-tasks") do
        expect(page).to have_content("Summary of neighbour responses")
      end
      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("Not started")
        click_link "Summary of neighbour responses"
      end

      within(".govuk-notification-banner") do
        expect(page).to have_content("View neighbour responses")
        expect(page).to have_content("There are 4 new neighbour responses")
      end

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.id}/assessment/assessment_details/new?category=neighbour_summary"
      )

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Summary of neighbour responses")
      end

      expect(page).to have_content("Add summary of neighbour responses")
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.full_address)

      click_button "Design responses (2)"
      expect(page).to have_content(objection_response.redacted_response)
      expect(page).to have_content(supportive_response1.redacted_response)
      click_button "Design responses (2)"

      click_button "Disabled access responses (2)"
      expect(page).to have_content(supportive_response2.redacted_response)
      expect(page).to have_content(objection_response.redacted_response)
      click_button "Disabled access responses (2)"

      click_button "Untagged responses (1)"
      expect(page).to have_content(neutral_response.redacted_response)
    end

    it "I can save and come back later when adding or editing neighbour responses" do
      expect(list_item("Check and assess")).to have_content("Not started")

      click_link "Check and assess"
      click_link "Summary of neighbour responses"

      within(".govuk-notification-banner") do
        expect(page).to have_content("View neighbour responses")
        expect(page).to have_content("There are 4 new neighbour responses")
      end

      fill_in "assessment_detail[design]", with: "A draft entry for the neighbour responses"
      click_button "Save and come back later"

      expect(page).to have_content("neighbour responses was successfully created.")

      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("In progress")
      end

      click_link "Summary of neighbour responses"
      expect(page).to have_content("Edit summary of neighbour responses")
      expect(page).to have_content("A draft entry for the neighbour responses")

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Summary of neighbour responses")
      end

      within(".govuk-notification-banner") do
        expect(page).to have_content("View neighbour responses")
        expect(page).to have_content("There are 0 new neighbour responses")
      end

      click_button "Save and come back later"
      expect(page).to have_content("neighbour responses was successfully updated.")

      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("In progress")
      end

      click_link("Application")

      expect(list_item("Check and assess")).to have_content("In progress")
    end

    it "I can save and mark as complete when adding neighbour responses" do
      click_link "Check and assess"
      click_link "Summary of neighbour responses"

      fill_in "assessment_detail[design]", with: "A complete entry for the design neighbour responses"
      fill_in "assessment_detail[disabled_access]", with: "A complete entry for the disabled access neighbour responses"
      fill_in "assessment_detail[untagged]", with: "A complete entry for the untagged neighbour responses"
      click_button "Save and mark as complete"

      expect(page).to have_content("neighbour responses was successfully created.")

      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("Completed")
      end

      click_link "Summary of neighbour responses"
      expect(page).to have_content("Summary of neighbour responses")
      expect(page).to have_content("Design: A complete entry for the design neighbour responses")
      expect(page).to have_content("Disabled access: A complete entry for the disabled access neighbour responses")
      expect(page).to have_content("Untagged: A complete entry for the untagged neighbour responses")

      expect(page).to have_link(
        "Edit summary of neighbour responses",
        href: edit_planning_application_assessment_assessment_detail_path(planning_application,
          AssessmentDetail.neighbour_summary.last, category: "neighbour_summary")
      )
    end

    it "shows errors" do
      click_link "Check and assess"
      click_link "Summary of neighbour responses"

      fill_in "assessment_detail[design]", with: "A complete entry for the design neighbour responses"
      fill_in "assessment_detail[disabled_access]", with: "A complete entry for the disabled access neighbour responses"
      click_button "Save and mark as complete"

      expect(page).to have_content "Fill in all summaries of comments"
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      expect(page).not_to have_link("neighbour responses")

      visit "/planning_applications/#{planning_application.id}/assessment/assessment_details/new"

      expect(page).to have_content("forbidden")
    end
  end

  context "when it's an LDC application" do
    let!(:application_type) { create(:application_type) }
    let!(:planning_application) do
      create(:planning_application, :in_assessment, application_type:, local_authority: default_local_authority)
    end

    it "does not show neighbour responses as an option" do
      click_link "Check and assess"

      within("#assessment-information-tasks") do
        expect(page).not_to have_content("Summary of neighbour responses")
      end
    end
  end
end
