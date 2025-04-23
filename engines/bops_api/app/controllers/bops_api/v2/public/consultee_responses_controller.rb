# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class ConsulteeResponsesController < PublicController
        def index
          @planning_application = find_planning_application params[:planning_application_id]
          return render json: {error: "Planning application not found"}, status: :not_found unless @planning_application

          @consultation = @planning_application.consultation
          if @consultation.nil?
            raise BopsApi::Errors::InvalidRequestError, "Consultation not found"
          end
          @consultee_responses = @consultation.consultee_responses.redacted

          @total_responses = @consultee_responses.count
          @total_consulted = @consultation.consultees.count

          @response_summary = calculate_response_summary(@consultee_responses)

          # @response_summary = @consultee_responses.group(:summary_tag)
          #   .unscope(:order) # Remove default ORDER BY clause
          #   .count
          @response_summary = {
            approved: @response_summary["approved"] || 0,
            objected: @response_summary["objected"] || 0,
            amendments_needed: @response_summary["amendments_needed"] || 0
          }

          @pagy, @comments = BopsApi::Postsubmission::CommentsSpecialistService.new(
            @consultee_responses,
            pagination_params
          ).call

          respond_to do |format|
            format.json
          end
        end

        private

        def calculate_response_summary(consultee_responses)
          summary = consultee_responses.group(:summary_tag).unscope(:order).count
          {
            supportive: summary["approved"] || 0,
            objection: summary["objected"] || 0,
            neutral: summary["amendments_needed"] || 0
          }
        end

        # Permit and return the required parameters
        def pagination_params
          params.permit(:sortBy, :orderBy, :resultsPerPage, :sentiment, :publishedAtFrom, :publishedAtTo, :query, :page, :format, :planning_application_id)
        end
      end
    end
  end
end
