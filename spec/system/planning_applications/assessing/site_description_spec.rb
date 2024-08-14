# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site description" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "when planning application is in assessment" do
    before do
      click_link "Check and assess"
    end

    it "I can view the information on the site description page" do
      within("#assessment-information-tasks") do
        expect(page).to have_content("Not started")
        click_link "Site description"
      end

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Site description")
      end

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/assessment/assessment_details/new?category=site_description"
      )

      expect(page).to have_link(
        "View site on Google Maps",
        href: "https://google.co.uk/maps/place/#{CGI.escape(planning_application.full_address)}"
      )

      expect(page).to have_content("Create a description of the site")
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content("You can include:")

      within(".govuk-warning-text") do
        expect(page).to have_content("This information WILL be made publicly available.")
      end
    end

    it "there is a validation error when submitting an empty text field" do
      click_link "Site description"

      click_button "Save and mark as complete"
      within(".govuk-error-summary") do
        expect(page).to have_content "Entry can't be blank"
      end

      click_button "Save and come back later"
      within(".govuk-error-summary") do
        expect(page).to have_content "Entry can't be blank"
      end
    end

    it "I can save and come back later when adding or editing a site description" do
      click_link "Site description"

      fill_in "assessment_detail[entry]", with: "A draft entry for the site description"
      click_button "Save and come back later"

      expect(page).to have_content("Site description was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end

      click_link "Site description"
      expect(page).to have_content("Edit site description")
      expect(page).to have_content("A draft entry for the site description")

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Site description")
      end

      click_button "Save and come back later"
      expect(page).to have_content("Site description was successfully updated.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end
    end

    it "I can save and mark as complete when adding a site description" do
      click_link "Site description"

      fill_in "assessment_detail[entry]", with: "A complete entry for the site description"
      click_button "Save and mark as complete"

      expect(page).to have_content("Site description was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("Completed")
      end

      click_link "Site description"
      expect(page).to have_content("Site description")
      expect(page).to have_content("A complete entry for the site description")

      expect(page).to have_link(
        "Edit site description",
        href: edit_planning_application_assessment_assessment_detail_path(planning_application, AssessmentDetail.site_description.last, category: :site_description)
      )
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      expect(page).not_to have_link("Site description")

      visit "/planning_applications/#{planning_application.reference}/assessment/assessment_details/new"

      expect(page).to have_content("The planning application must be validated before assessment can begin")
    end
  end
end
