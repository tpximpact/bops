# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class CommentsPublicService < CommentsBaseService
      private

      # Defines allowed fields and their default sort orders
      def allowed_sort_fields
        {
          "receivedAt" => {column: "received_at", default_order: "desc"},
          "id" => {column: "neighbour_responses.id", default_order: "asc"}
        }
      end

      def response_table_name
        "neighbour_responses"
      end

      def translated_sentiment(sentiment)
        sentiment
      end
    end
  end
end
