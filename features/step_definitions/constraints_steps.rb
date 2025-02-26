# frozen_string_literal: true

Given("the planning application has the {string} constraint") do |constraint|
  @planning_application.planning_application_constraints.select { |k, v| k.type_code == constraint }
end

Given("I visit the application's constraints form") do
  steps %(
    Given I view the planning application
    And I press "Check and assess"
    And I press "Constraints"
    And I press "Update constraints"
  )
end
