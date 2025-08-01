# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ProposalParser < BaseParser
      def parse
        return {} if params.blank?

        case source
        when "Planning Portal"
          parse_planning_portal
        when "PlanX"
          parse_planx
        end
      end

      private

      def parse_planning_portal
        {
          description: params.dig("applicationData", "proposalDescription", "descriptionText"),
          boundary_geojson: build_boundary_feature
        }
      end

      def parse_planx
        {
          description: params[:description],
          boundary_geojson: params.dig("boundary", "site")&.to_json
        }
      end

      def build_boundary_feature
        boundary = params.dig("polygon", "features", 0).deep_dup
        return unless boundary.is_a?(Hash)

        geometry = boundary["geometry"]
        return unless geometry.is_a?(Hash) && geometry["coordinates"].is_a?(Array)

        transformed_coords = geometry["coordinates"].map do |polygon|
          polygon.map do |ring|
            ring.map { |coord| OsNationalGrid.os_ng_to_wgs84(coord[0].to_f, coord[1].to_f) }
          end
        end

        geometry["coordinates"] = transformed_coords
        boundary
      end
    end
  end
end
