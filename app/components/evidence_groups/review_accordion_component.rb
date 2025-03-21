# frozen_string_literal: true

module EvidenceGroups
  class ReviewAccordionComponent < ViewComponent::Base
    include ApplicationHelper

    def initialize(planning_application:, sections: default_sections)
      @planning_application = planning_application
      @sections = sections
    end

    private

    attr_reader :planning_application, :sections
  end
end
