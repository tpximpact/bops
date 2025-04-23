# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class CommentsBaseService
      include BopsApi::PostsubmissionApplicationSchemaHelper

      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      attr_reader :scope, :params

      def call
        paginate(
          sort_results(
            filter_by(scope)
          )
        )
      end

      private

      # Defines what can be filtered
      def filter_by(scope)
        if params[:query].present?
          scope = scope.where("redacted_response ILIKE ?", "%#{params[:query]}%")
        end

        # Filter by sentiment
        if params[:sentiment].present?
          scope = scope.where(summary_tag: translated_sentiment(params[:sentiment]))
        end

        # Filter by publishedAtFrom
        if params[:publishedAtFrom].present?
          datetime = parse_and_format_date(params[:publishedAtFrom])
          # datetime = format_postsubmission_date(params[:publishedAtFrom])
          if datetime
            scope = scope.where("#{response_table_name}.updated_at >= ?", datetime)
          else
    # Handle the case where the date is invalid
    # You might want to log this or raise an error
          end
          # scope = scope.where("#{response_table_name}.updated_at >= ?", datetime)
        end

        # Filter by publishedAtTo
        if params[:publishedAtTo].present?
          datetime = format_postsubmission_date(params[:publishedAtTo])
          scope = scope.where("#{response_table_name}.updated_at <= ?", datetime)
        end

        scope
      end

      def parse_and_format_date(date_string)
        begin
          # Assuming the date is in 'dd/mm/yyyy' format
          Date.strptime(date_string, '%d/%m/%Y').beginning_of_day
        rescue ArgumentError
          nil # Return nil if the date is invalid
        end
      end

      # Defines allowed fields and their default sort orders
      def allowed_sort_fields
        {
          "receivedAt" => {column: "received_at", default_order: "desc"}
        }
      end

      # Define allowed orderBy values
      def allowed_order_values
        %w[asc desc]
      end

      # Default sortBy
      def default_sort_by
        "receivedAt"
      end

      # Defines how results are sorted based on the sortBy and orderBy parameters
      def sort_results(scope)
        # Validate sortBy if it is explicitly set
        if params[:sortBy].present?
          sort_by = params[:sortBy]&.camelize(:lower)
          unless allowed_sort_fields.key?(sort_by)
            raise ArgumentError, "Invalid sortBy field: #{params[:sortBy]}. Allowed fields are: #{allowed_sort_fields.keys.join(", ")}"
          end
        else
          sort_by = default_sort_by
        end

        # Validate orderBy if it is explicitly set
        if params[:orderBy].present?
          order_by = params[:orderBy]
          unless allowed_order_values.include?(order_by)
            raise ArgumentError, "Invalid orderBy value: #{params[:orderBy]}. Allowed values are: #{allowed_order_values.join(", ")}"
          end
        else
          order_by = allowed_sort_fields[sort_by][:default_order] # Default orderBy
        end

        # Apply sorting to the scope
        sort_field = allowed_sort_fields[sort_by]
        scope.reorder("#{sort_field[:column]} #{order_by}")
      end

      def paginate(scope)
        BopsApi::Postsubmission::PostsubmissionPagination.new(scope: scope, params: params).call
      end
    end
  end
end
