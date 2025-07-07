# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class PlanningApplicationsController < PublicController
        def search
          @pagy, planning_applications = search_service(planning_applications_scope.by_created_at_desc).call
          # @pagy, planning_applications = search_service(planning_applications_scope.by_latest_published).call
          # @planning_applications = planning_applications.map { |pa| BopsApi::Postsubmission::PlanningApplicationPresenter.new(pa) }
          @planning_applications = planning_applications.filter_map do |pa|
            begin
              BopsApi::Postsubmission::PlanningApplicationPresenter.new(pa)
            rescue => e
              Rails.logger.warn("Skipping planning application #{pa.id}: #{e.message}")
              nil
            end
          end
          
          respond_to do |format|
            format.json { render json: @planning_applications }
            # format.json
          end
        end

        def show
          planning_application = find_planning_application params[:id]
          @planning_application = BopsApi::Postsubmission::PlanningApplicationPresenter.new(planning_application)

          respond_to do |format|
            # format.json { render json: @planning_application }
            format.json
          end
        end
      end
    end
  end
end
