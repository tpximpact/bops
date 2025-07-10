# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class ConsulteeResponsesController < PublicController
        def index
          @planning_application = find_planning_application params[:planning_application_id]
          @consultation = @planning_application.consultation
          if @consultation.nil?
            raise BopsApi::Errors::InvalidRequestError, "Consultation not found"
          end
          @consultee_responses = @consultation.consultee_responses.redacted

          sentiments = normalize_sentiments_from_query_string(request.env["QUERY_STRING"])
          updated_params = pagination_params.to_h.merge(sentiment: sentiments)

          @total_available_items = @consultee_responses.count
          @total_consulted = @consultation.consultees.count

          @response_summary = @consultee_responses.group(:summary_tag)
            .unscope(:order) # Remove default ORDER BY clause
            .count
          @response_summary = {
            approved: @response_summary["approved"] || 0,
            objected: @response_summary["objected"] || 0,
            amendments_needed: @response_summary["amendments_needed"] || 0
          }

          @pagy, @comments = BopsApi::Postsubmission::CommentsSpecialistService.new(
            @consultee_responses,
            updated_params
          ).call

          respond_to do |format|
            format.json
          end
        end

        private

        # Permit and return the required parameters
        def pagination_params
          params.permit(:sortBy, :orderBy, :resultsPerPage, :query, :page, :format, :planning_application_id, :sentiment)
        end

        def normalize_sentiments_from_query_string(query_string)
          query_string.scan(/sentiment=([^&]*)/).flatten.map do |s|
            (s == "amendmentsNeeded") ? "amendments_needed" : s
          end
        end
      end
    end
  end
end
