# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assessment tasks", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor

    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  context "when the planning application is in_assessment, I can assess the planning application" do
    let(:planning_application) do
      create(
        :planning_application,
        :in_assessment,
        local_authority: default_local_authority
      )
    end

    context "when planning application is an LDC" do
      it "displays the assessment tasks list" do
        within(".app-task-list") do
          within("#check-consistency-assessment-tasks") do
            expect(page).to have_content("Check application")
            expect(page).to have_link("Check application details")
            expect(page).to have_link("Permitted development rights")

            expect(page).not_to have_link("Evidence of immunity")
          end

          within("#assessment-information-tasks") do
            expect(page).to have_content("Assessor remarks")
            expect(page).to have_link("Summary of works")
            expect(page).to have_link("Summary of additional evidence")
            expect(page).to have_link("Site description")
            expect(page).to have_link("Summary of consultation")
          end

          within("#assess-against-legislation-tasks") do
            expect(page).to have_content("Assess against legislation")
            expect(page).to have_link("Add new assessment area")
          end

          within("#complete-assessment-tasks") do
            expect(page).to have_content("Complete assessment")
            expect(page).to have_link("Review documents for recommendation")
            expect(page).to have_link("Make draft recommendation")
            expect(page).to have_content("Review and submit recommendation")
          end
        end
      end
    end

    context "when planning application is a prior approval" do
      before do
        application_type = create(:application_type, :prior_approval)
        planning_application.update(application_type:)
        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
      end

      it "displays the assessment tasks list" do
        within(".app-task-list") do
          within("#check-consistency-assessment-tasks") do
            expect(page).to have_content("Check application")
            expect(page).to have_link("Check application details")
            expect(page).to have_link("Permitted development rights")

            expect(page).not_to have_link("Evidence of immunity")
          end

          within("#assessment-information-tasks") do
            expect(page).to have_content("Assessor remarks")
            expect(page).to have_link("Summary of works")
            expect(page).to have_link("Summary of additional evidence")
            expect(page).to have_link("Site description")
            expect(page).not_to have_link("Summary of consultation")
            expect(page).to have_link("Amenity")
          end

          within("#assess-against-legislation-tasks") do
            expect(page).to have_content("Assess against legislation")
            expect(page).to have_link("Add new assessment area")
          end

          within("#complete-assessment-tasks") do
            expect(page).to have_content("Complete assessment")
            expect(page).to have_link("Review documents for recommendation")
            expect(page).to have_link("Make draft recommendation")
            expect(page).to have_content("Review and submit recommendation")
          end
        end
      end
    end
  end

  context "when the planning application is invalidated, I cannot access the assessment tasks" do
    let(:planning_application) do
      create(
        :planning_application,
        :invalidated,
        local_authority: default_local_authority
      )
    end

    it "displays a forbidden message" do
      expect(page).to have_content("The planning application must be validated before assessment can begin")
    end
  end

  context "when there are proposal details", :capybara do
    let(:planning_application) do
      create(
        :planning_application,
        proposal_details:,
        local_authority: default_local_authority
      )
    end

    let(:proposal_details) do
      [
        {
          question: "Question 1",
          responses: [{value: "Answer 1"}],
          metadata: {section_name: "About the property", auto_answered: true}
        },
        {
          question: "Question 2",
          responses: [{value: "Answer 2"}],
          metadata: {section_name: "About the property"}
        },
        {
          question: "Question 3",
          responses: [{value: "Answer 3"}],
          metadata: {section_name: "group_1", auto_answered: true}
        },
        {
          question: "Question 4",
          responses: [{value: "Answer 4"}]
        }
      ]
    end

    it "displays the proposal details by group" do
      click_button("Proposal details")
      click_link("About the property")

      expect(current_url).to have_target_id("abouttheproperty")

      within(find_all(".proposal-details-sub-list")[0]) do
        expect(page).to have_content("1.  Question 1")
        expect(page).to have_content("2.  Question 2")
      end

      click_link("Group 1")

      expect(current_url).to have_target_id("group1")

      expect(
        find_all(".proposal-details-sub-list")[1]
      ).to have_content(
        "3.  Question 3"
      )

      click_link("Other")

      expect(current_url).to have_target_id("other")

      expect(
        find_all(".proposal-details-sub-list")[2]
      ).to have_content(
        "4.  Question 4"
      )
    end

    it "lets user filter out auto answered proposal_details" do
      click_button("Proposal details")
      check("View ONLY applicant answers, hide 'Auto-answered by PlanX")

      expect(page).to have_text(:visible, "About the property")
      expect(page).not_to have_text(:visible, "Group 1")
      expect(page).to have_text(:visible, "Other")

      within(find_all(".proposal-details-sub-list", visible: true)[0]) do
        expect(page).not_to have_text(:visible, "1. \nQuestion 1")
        expect(page).to have_text(:visible, "2. \nQuestion 2")
      end

      expect(page).not_to have_text(:visible, "3. \nQuestion 3")

      expect(
        find_all(".proposal-details-sub-list", visible: true)[1]
      ).to have_text(
        :visible, "4. \nQuestion 4"
      )
    end

    it "lets user navigate back to top of proposal details section" do
      click_button("Proposal details")
      click_link("Group 1")

      expect(current_url).to have_target_id("group1")

      first(:link, "Back to top").click

      expect(current_url).to have_target_id("accordion-default-heading-proposal_details")
    end
  end

  context "when the application may be immune" do
    let(:planning_application) do
      create(
        :planning_application,
        :in_assessment,
        :with_immunity,
        local_authority: default_local_authority
      )
    end

    it "allows me to assess the evidence of immunity" do
      within(".app-task-list") do
        within("#check-consistency-assessment-tasks") do
          expect(page).to have_content("Check application")
          expect(page).to have_link("Check application details")
          expect(page).to have_link("Evidence of immunity")
          expect(page).to have_link("Immunity/permitted development rights")
        end
      end
    end
  end
end
