# frozen_string_literal: true

class AddReportingTypeToPlanningApplications < ActiveRecord::Migration[7.0]
  class ApplicationType < ActiveRecord::Base; end

  class PlanningApplication < ActiveRecord::Base
    belongs_to :application_type
  end

  def change
    add_column :planning_applications, :reporting_type, :string

    up_only do
      PlanningApplication.find_each do |pa|
        case pa.application_type.name
        when "lawfulness_certificate"
          pa.update_column(:reporting_type, "Q26")
        when "prior_approval"
          pa.update_column(:reporting_type, "PA1")
        when "planning_permission"
          pa.update_column(:reporting_type, "Q21")
        end
      end
    end
  end
end
