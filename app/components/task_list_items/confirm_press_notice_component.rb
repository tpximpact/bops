# frozen_string_literal: true

module TaskListItems
  class ConfirmPressNoticeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @press_notice = planning_application.press_notice
    end

    private

    attr_reader :planning_application, :press_notice

    def link_text
      "Confirm press notice"
    end

    def link_active?
      press_notice.try(:required)
    end

    def link_path
      planning_application_press_notice_confirmation_path(planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status:)
    end

    def status
      return "complete" if press_notice&.published_at?

      "not_started"
    end
  end
end
