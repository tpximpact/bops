# frozen_string_literal: true

module TaskListItems
  module Assessment
    class ImmunityDetailsComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate(:immunity_detail, to: :planning_application)

      def link_text
        t(".evidence_of_immunity")
      end

      def link_path
        case status
        when :not_started
          new_planning_application_assessment_immunity_detail_path(
            planning_application
          )
        when :in_progress, :to_be_reviewed
          edit_planning_application_assessment_immunity_detail_path(
            planning_application,
            immunity_detail
          )
        when :complete
          planning_application_assessment_immunity_detail_path(
            planning_application,
            immunity_detail
          )
        end
      end

      def status
        if (review = immunity_detail.current_evidence_review)
          review.status.to_sym
        else
          :not_started
        end
      end

      def to_be_reviewed?
        planning_application.recommendation&.rejected? &&
          immunity_detail.update_required?
      end
    end
  end
end
