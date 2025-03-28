# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ImmunityDetailsController < BaseController
      before_action :set_immunity_detail
      before_action :ensure_planning_application_is_not_preapp

      def show
        respond_to do |format|
          format.html
        end
      end

      def new
        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @immunity_detail.update(immunity_details_params)
            format.html do
              redirect_to planning_application_assessment_tasks_path(@planning_application),
                notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def set_immunity_detail
        @immunity_detail = @planning_application.immunity_detail
      end

      def immunity_details_params
        params.require(:immunity_detail)
          .permit(
            evidence_groups_attributes:
              [
                :id,
                :start_date,
                :end_date,
                :missing_evidence,
                :missing_evidence_entry,
                {comments_attributes: [:text]}
              ]
          )
          .merge(reviews_attributes: [
            status:,
            specific_attributes: {"review_type" => "evidence"},
            id: (@immunity_detail&.current_evidence_review_immunity_detail&.id if !mark_as_complete?)
          ])
      end

      def status
        save_progress? ? :in_progress : :complete
      end
    end
  end
end
