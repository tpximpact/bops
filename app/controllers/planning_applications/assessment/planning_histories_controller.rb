# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class PlanningHistoriesController < BaseController
      before_action :ensure_planning_history_is_enabled

      def show
        @planning_history = Apis::Paapi::Query.new.fetch(@planning_application.uprn)

        respond_to do |format|
          format.html
        end
      end

      private

      def ensure_planning_history_is_enabled
        return if @planning_application.planning_history_enabled?

        render plain: "forbidden", status: :forbidden
      end
    end
  end
end
