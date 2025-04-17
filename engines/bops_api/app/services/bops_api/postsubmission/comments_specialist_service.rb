# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class CommentsSpecialistService < CommentsBaseService
      private

      # Defines allowed fields and their default sort orders
      def allowed_sort_fields
        {
          "receivedAt" => {column: "received_at", default_order: "desc"},
          "id" => {column: "consultee_responses.id", default_order: "asc"}
        }
      end

      def response_table_name
        "consultee_responses"
      end

      def translated_sentiment(sentiment)
        {
          "supportive" => "approved",
          "objection" => "objected",
          "neutral" => "amendments_needed"
        }[sentiment] || sentiment
      end
    end
  end
end
