# frozen_string_literal: true

module Api
  module V1
    class TimeExtensionValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :set_time_extension_validation_request, only: %i[show update]

      rescue_from ValidationRequestUpdateService::UpdateError do |error|
        render json: {message: error.message}, status: :bad_request
      end

      rescue_from ActiveRecord::RecordNotFound do
        render json: {message: "Unable to find time extension validation request with id: #{params[:id]}"},
          status: :not_found
      end

      def index
        respond_to do |format|
          format.json do
            @time_extension_validation_requests = @planning_application.time_extension_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          format.json
        end
      end

      def update
        ValidationRequestUpdateService.new(
          validation_request: @time_extension_validation_request,
          params:
        ).call!

        render json: {message: "Change request updated"}, status: :ok
      end

      private

      def set_time_extension_validation_request
        @time_extension_validation_request = @planning_application.time_extension_validation_requests.find(params[:id])
      end
    end
  end
end
