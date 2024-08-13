# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assess immunity detail permitted development right", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end
  let!(:immunity_detail) { create(:immunity_detail, planning_application:) }

  context "when assessing whether an application is immune" do
    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
      click_link("Check and assess")
      click_link("Immunity/permitted development rights")
    end

    context "when there are validation errors" do
      it "displays an error if an option for the decision has not been selected" do
        click_button "Save and mark as complete"

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
          expect(page).to have_content("Select Yes or No for whether the application is immune from enforcement")
          expect(page).to have_content("Decision reason for why the application is immune can't be blank")
        end
      end

      it "displays an error if no reason for a 'Yes' decision has been given" do
        within("#assess-immunity-detail-section") do
          choose "Yes"
        end
        click_button "Save and mark as complete"

        within(".govuk-error-summary") do
          expect(page).to have_content("Decision reason for why the application is immune can't be blank")
          expect(page).to have_content("Immunity from enforcement summary can't be blank")
        end
      end

      it "displays an error if no reason or response to permitted development rights for a 'No' decision has been given" do
        within("#assess-immunity-detail-section") do
          choose "No"
        end
        click_button "Save and mark as complete"

        within(".govuk-error-summary") do
          expect(page).to have_content("Decision reason for why the application is immune can't be blank")
          expect(page).to have_content("Select Yes or No for the permitted development rights")
        end
      end

      it "displays an error if no reason for removing permitted development rights has been given" do
        within("#assess-immunity-detail-section") do
          choose "No"
        end
        within("#permitted-development-right-section") do
          choose "Yes"
        end
        click_button "Save and mark as complete"

        within(".govuk-error-summary") do
          expect(page).to have_content("Removed reason for the permitted development rights can't be blank")
        end
      end
    end

    context "when viewing the content", :capybara do
      before do
        Capybara.ignore_hidden_elements = true
      end

      after do
        Capybara.ignore_hidden_elements = false
      end

      it "I see the relevant information" do
        expect(page).to have_content("Immunity/permitted development rights")
        expect(page).to have_css("#planning-application-details")
        expect(page).to have_css("#constraints-section")
        expect(page).to have_css("#planning-history-section")

        expect(page).to have_content("Is the application immune from enforcement?")
        # Does not show summary field until decision is chosen
        expect(page).not_to have_content("Immunity from enforcement summary")

        within("#assess-immunity-detail-section") do
          choose "Yes"
          # Does not show permitted development rights section when decision is "Yes"
          expect(page).not_to have_css("#permitted-development-right-section")
        end

        within("#assess-immunity-detail-section") do
          choose "No"
          # Does not show summary field
          expect(page).not_to have_content("Immunity from enforcement summary")
        end
      end
    end

    context "when I assess whether the application is immune from enforcement" do
      it "I can choose 'Yes' and select a reason" do
        within("#assess-immunity-detail-section") do
          choose "Yes"

          within(".govuk-radios") do
            expect(page).to have_content("no action is taken within 4 years of substantial completion for a breach of planning control consisting of operational development")
            expect(page).to have_content("no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse")
            expect(page).to have_content("no action is taken within 10 years for any other breach of planning control (essentially other changes of use)")

            choose "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse"
          end

          fill_in "Immunity from enforcement summary", with: "A summary"
        end

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully created")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          status: "complete",
          review_status: "review_not_started",
          action: nil,
          specific_attributes: {
            "decision" => "Yes",
            "decision_reason" => "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse",
            "decision_type" => "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse",
            "summary" => "A summary",
            "review_type" => "enforcement"
          }
        )

        within("#immunity-permitted-development-rights") do
          expect(page).to have_link(
            "Immunity/permitted development rights",
            href: planning_application_assessment_assess_immunity_detail_permitted_development_right_path(planning_application)
          )
          expect(page).to have_content("Completed")
        end
      end

      it "I can choose 'Yes' and give an other reason" do
        within("#assess-immunity-detail-section") do
          choose "Yes"

          within(".govuk-radios") do
            choose "other"
            fill_in "Please provide a reason", with: "A reason for my decision"
          end

          fill_in "Immunity from enforcement summary", with: "A summary"
        end

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully created")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          status: "complete",
          review_status: "review_not_started",
          specific_attributes: {
            "decision" => "Yes",
            "decision_reason" => "A reason for my decision",
            "decision_type" => "other",
            "summary" => "A summary",
            "review_type" => "enforcement"
          }
        )
        expect(PermittedDevelopmentRight.all.length).to eq(0)
      end

      it "I choose 'Yes' after originally selecting 'No'" do
        within("#assess-immunity-detail-section") do
          choose "No"

          fill_in "Describe why the application is not immune from enforcement", with: "Application is not immune"
        end

        within("#permitted-development-right-section") do
          choose "Yes"

          fill_in "Describe how permitted development rights have been removed", with: "A reason"
        end

        within("#assess-immunity-detail-section") do
          choose "Yes"

          within(".govuk-radios") do
            choose "other"
            fill_in "Please provide a reason", with: "A reason for my decision"
          end

          fill_in "Immunity from enforcement summary", with: "A summary"
        end

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully created")

        expect(Review.where(owner_type: "ImmunityDetail").length).to eq(1)
        # No permitted development right response is created
        expect(PermittedDevelopmentRight.all.length).to eq(0)
      end

      it "I can choose 'No' and respond to the permitted development rights" do
        within("#assess-immunity-detail-section") do
          choose "No"

          fill_in "Describe why the application is not immune from enforcement", with: "Application is not immune"
        end

        within("#permitted-development-right-section") do
          choose "Yes"

          fill_in "Describe how permitted development rights have been removed", with: "A reason"
        end

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully created")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          specific_attributes: {
            "decision" => "No",
            "decision_reason" => "Application is not immune",
            "review_type" => "enforcement",
            "summary" => ""
          }
        )
        expect(PermittedDevelopmentRight.last).to have_attributes(
          assessor_id: assessor.id,
          removed: true,
          removed_reason: "A reason",
          status: "removed"
        )
      end

      it "I can view and edit my response", :capybara do
        within("#assess-immunity-detail-section") do
          choose "No"

          fill_in "Describe why the application is not immune from enforcement", with: "Application is not immune"
        end

        within("#permitted-development-right-section") do
          choose "Yes"

          fill_in "Describe how permitted development rights have been removed", with: "A reason"
        end

        click_button "Save and mark as complete"

        # View show page
        click_link "Immunity/permitted development rights"

        expect(page).to have_content("Immunity/permitted development rights")
        expect(page).to have_css("#planning-application-details")
        expect(page).to have_css("#constraints-section")
        expect(page).to have_css("#planning-history-section")
        expect(page).to have_css(".immunity-section")

        expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
        expect(page).to have_content("Yes")
        expect(page).to have_content("A reason")

        expect(page).to have_content("Is the application immune from enforcement?")
        expect(page).not_to have_content("Immunity from enforcement summary")
        expect(page).to have_content("Assessor decision: No")
        expect(page).to have_content("Reason: Application is not immune")
        expect(page).to have_content("Is the application immune from enforcement?")

        # View edit page
        click_link "Edit immunity/permitted development rights"
        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-review-decision-yes-field").selected?).to be(false)
        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-review-decision-no-field").selected?).to be(true)

        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-review-no-decision-reason-field").value).to eq("Application is not immune")
        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-permitted-development-right-removed-true-field").selected?).to be(true)
        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-permitted-development-right-removed-field").selected?).to be(false)
        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-permitted-development-right-removed-reason-field").value).to eq("A reason")

        within("#assess-immunity-detail-section") do
          choose "Yes"

          within(".govuk-radios") do
            choose "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse"
          end

          fill_in "Immunity from enforcement summary", with: "A summary"
        end

        click_button "Save and mark as complete"
        click_link "Immunity/permitted development rights"
        click_link "Edit immunity/permitted development rights"

        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-review-decision-yes-field").selected?).to be(true)
        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-review-decision-no-field").selected?).to be(false)
        expect(
          find_by_id(
            "assess-immunity-detail-permitted-development-right-form-review-decision-type-no-action-is-taken-within-4-years-for-an-unauthorised-change-of-use-to-a-single-dwellinghouse-field"
          ).selected?
        ).to be(true)
        expect(find_by_id("assess-immunity-detail-permitted-development-right-form-review-summary-field").value).to eq("A summary")

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          specific_attributes: {
            "decision" => "Yes",
            "decision_reason" => "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse",
            "decision_type" => "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse",
            "review_type" => "enforcement",
            "summary" => "A summary"
          }
        )

        click_link "Immunity/permitted development rights"

        expect(page).not_to have_content("Have the permitted development rights relevant for this application been removed?")

        expect(page).to have_content("Is the application immune from enforcement?")
        expect(page).not_to have_content("Immunity from enforcement summary")
        expect(page).to have_content("Assessor decision: Yes")
        expect(page).to have_content("Reason: no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse")
        expect(page).to have_content("Summary: A summary")
      end
    end
  end

  context "when there is an open review" do
    before do
      create(:review, :enforcement, owner: immunity_detail)

      sign_in assessor
    end

    it "I cannot create a new permitted development right request when there is an open response" do
      visit "/planning_applications/#{planning_application.reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      within("#assess-immunity-detail-section") do
        choose "Yes"
        choose "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse"
        fill_in "Immunity from enforcement summary", with: "A summary"
      end

      click_button "Save and mark as complete"
      expect(page).to have_text("Cannot create an enforcement review immunity detail response when there is already an open response")

      expect(Review.where(owner_type: "ImmunityDetail").count).to eq(1)
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"

      expect(page).not_to have_link("Immunity/permitted development rights")

      visit "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/new"

      expect(page).to have_content("The planning application must be validated before assessment can begin")
    end
  end

  context "when planning application is not possibly immune" do
    before { allow_any_instance_of(PlanningApplication).to receive(:possibly_immune?).and_return(false) }

    it "does not allow me to visit the page" do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"

      click_link "Check and assess"
      expect(page).not_to have_link("Immunity/permitted development rights")

      visit "/planning_applications/#{planning_application.reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("forbidden")
    end
  end

  context "when it has no evidence attached" do
    it "I can view the information on the permitted development rights page" do
      create(:immunity_detail, planning_application:)
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Evidence cover: Unknown")
      expect(page).to have_content("Missing evidence (gap in time): No")
    end
  end

  context "when it has evidence attached" do
    let(:immunity_detail) do
      create(:immunity_detail, planning_application:)
    end

    before do
      sign_in assessor
    end

    it "lists the evidence in a single group for a single document" do
      document = create(:document, tags: %w[councilTaxBill])
      immunity_detail.add_document(document)
      visit "/planning_applications/#{planning_application.reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Council tax bills (1)")
    end

    it "lists the evidence in a single group for multiple documents of the same kind" do
      document1 = create(:document, tags: %w[councilTaxBill])
      document2 = create(:document, tags: %w[councilTaxBill])
      immunity_detail.add_document(document1)
      immunity_detail.add_document(document2)
      visit "/planning_applications/#{planning_application.reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Council tax bills (2)")
    end

    it "lists the evidence in multiple groups for multiple documents of different kind" do
      document1 = create(:document, tags: %w[councilTaxBill])
      document2 = create(:document, tags: %w[photographs.existing])
      immunity_detail.add_document(document1)
      immunity_detail.add_document(document2)
      visit "/planning_applications/#{planning_application.reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Council tax bills (1)")
      expect(page).to have_content("Photographs - existings (1)")
    end
  end
end
