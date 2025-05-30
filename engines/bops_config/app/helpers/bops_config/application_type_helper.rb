# frozen_string_literal: true

module BopsConfig
  module ApplicationTypeHelper
    COLOURS = {
      active: "green",
      inactive: "grey",
      retired: "red"
    }.freeze

    def tag_colour(tag)
      COLOURS[tag.to_sym]
    end

    def application_details_features
      %i[
        heads_of_terms
        informatives
        assess_against_policies
        considerations
        legislative_requirements
        permitted_development_rights
        planning_conditions
        cil
        eia
        ownership_details
        site_visits
        description_change_requires_validation
        publishable
      ]
    end
  end
end
