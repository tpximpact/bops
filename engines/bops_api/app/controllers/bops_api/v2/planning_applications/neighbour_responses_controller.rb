# frozen_string_literal: true

module BopsApi
  module V2
    module PlanningApplications
      class NeighbourResponsesController < AuthenticatedController
        def create
          @planning_application = find_planning_application(params[:planning_application_id])
          @consultation = @planning_application.consultation
          neighbour_response = build_neighbour_response

          neighbour_response.save!

          render json: {
            data: nil,
            status: {
              code: 200,
              message: "OK",
              detail: "Neighbour response created successfully"
            }
          }, status: :ok
        rescue ActiveRecord::RecordInvalid
          render json: {
            data: nil,
            status: {
              code: 422,
              message: "Unprocessable Entity",
              detail: neighbour_response.errors.full_messages.to_sentence
            }
          }, status: :unprocessable_entity
        end

        def required_api_key_scope = "comment"

          private

          def build_neighbour_response
            @consultation.neighbour_responses.build(response_attributes).tap do |response|
              response.neighbour = find_or_create_neighbour
            end
          end

          def find_or_create_neighbour
            @consultation.neighbours.find_by(address: params[:address]) ||
              @consultation.neighbours.build(
                address: params[:address],
                selected: false,
                source: "sent_comment"
              )
          end

          def response_attributes
            response_params.except(:address, :planning_application_id).merge!(
              received_at: Time.zone.now,
              consultation_id: @consultation.id
            )
          end

          def response_params
            params.permit(
              :address, :name, :email, :response, :summary_tag,
              :redacted_response, tags: []
            )
          end
      end
    end
  end
end
