# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class AssessImmunityDetailPermittedDevelopmentRightsController < BaseController
      include PermittedDevelopmentRights

      rescue_from ::Review::NotCreatableError, with: :redirect_failed_create_error

      before_action :ensure_planning_application_is_possibly_immune
      before_action :set_permitted_development_right, only: %i[show edit update]
      before_action :set_permitted_development_rights, only: %i[new show edit]
      before_action :set_review_immunity_details, only: %i[new show edit]
      before_action :set_review_immunity_detail, only: %i[show edit update]
      before_action :ensure_review_immunity_detail_is_editable, only: %i[edit update]

      def show
        respond_to do |format|
          format.html
        end
      end

      def new
        @permitted_development_right = @planning_application.permitted_development_rights.new
        @review_immunity_detail = @planning_application.immunity_detail.reviews.new

        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application
        )

        respond_to do |format|
          format.html
        end
      end

      def edit
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application
        )

        respond_to do |format|
          format.html
        end
      end

      def create
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application,
          params: assess_immunity_detail_permitted_development_right_form_params
        )

        if @form.save
          redirect_to planning_application_assessment_tasks_path(@planning_application),
            notice: I18n.t("planning_applications.assessment.assess_immunity_detail_permitted_development_rights.successfully_created")
        else
          set_permitted_development_rights
          set_review_immunity_details
          render :new
        end
      end

      def update
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application,
          params: assess_immunity_detail_permitted_development_right_form_params,
          review_immunity_detail: @review_immunity_detail,
          permitted_development_right: @permitted_development_right
        )

        if @form.update
          redirect_to redirect_path, notice: I18n.t("planning_applications.assessment.assess_immunity_detail_permitted_development_rights.successfully_updated")
        else
          set_permitted_development_rights
          set_review_immunity_details
          render :edit
        end
      end

      private

      def assess_immunity_detail_permitted_development_right_form_params
        params.require(:assess_immunity_detail_permitted_development_right_form)
          .permit(
            review: %i[decision decision_reason yes_decision_reason no_decision_reason decision_type summary],
            permitted_development_right: %i[removed removed_reason]
          )
          .merge(status:, permitted_development_right_status:)
      end

      def ensure_planning_application_is_possibly_immune
        return if @planning_application.possibly_immune?

        render plain: "forbidden", status: :forbidden
      end

      def ensure_review_immunity_detail_is_editable
        return unless @review_immunity_detail.accepted?

        render plain: "forbidden", status: :forbidden
      end

      def set_review_immunity_details
        @review_immunity_details =
          @planning_application.immunity_detail.reviews.enforcement.reviewer_not_accepted
      end

      def set_review_immunity_detail
        @review_immunity_detail = @planning_application.immunity_detail.current_enforcement_review_immunity_detail
      end

      def status
        save_progress? ? "in_progress" : "complete"
      end

      def permitted_development_right_status
        save_progress? ? "in_progress" : "complete"
      end

      def redirect_failed_create_error(error)
        redirect_to planning_application_assessment_tasks_path(@planning_application), alert: error.message
      end

      def redirect_path
        if current_user.reviewer?
          planning_application_review_tasks_path(@planning_application)
        else
          planning_application_assessment_tasks_path(@planning_application)
        end
      end
    end
  end
end
