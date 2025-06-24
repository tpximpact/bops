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

          raw_query_string = request.env['QUERY_STRING']
          sentiments = extract_sentiments_from_query(raw_query_string)
          updated_params = pagination_params.to_h.merge(sentiment: sentiments)

          @total_responses = @consultee_responses.count
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
        def extract_sentiments_from_query(query_string)
          # Use a regular expression to find all occurrences of the sentiment parameter
          query_string.scan(/sentiment=([^&]*)/).flatten
        end
      end
    end
  end
end
