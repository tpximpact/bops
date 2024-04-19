# frozen_string_literal: true

module StatusTags
  class AssessRecommendationComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    delegate(:recommendation, to: :planning_application)

    def status
      if planning_application.can_assess? && recommendation.blank?
        :not_started
      elsif recommendation&.rejected?
        :to_be_reviewed
      elsif recommendation&.assessment_in_progress?
        :in_progress
      else
        :complete
      end
    end
  end
end
