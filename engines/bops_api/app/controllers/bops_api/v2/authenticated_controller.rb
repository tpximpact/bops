# frozen_string_literal: true

module BopsApi
  module V2
    class AuthenticatedController < ApplicationController
      before_action :authenticate

      private

      def authenticate
        user = authenticate_with_http_token do |token, options|
          @local_authority.api_users.authenticate(token)
        end

        if user
          @current_user = user
        else
          json = {
            error: {
              code: 401,
              message: "Unauthorized"
            }
          }

          render json: json, status: :unauthorized
        end
      end

      def planning_applications_scope
        @local_authority.planning_applications.includes(:user)
      end
    end
  end
end
