Feature: Uploading documents for an application
  Background:
    Given I am logged in as an assessor
    And my name is "Morisuke"
    And a new planning application
    When I manage the application's documents

  Scenario: I can upload a new document with a reference, received date and tags
    Given I press "Upload document"
    And I upload "spec/fixtures/images/proposed-floorplan.png" for the "file" input
    And I set the date inputs to "5/7/2021"
    And I click "Edit tags"
    And I check "Floor plan - existing"
    And I check "Roof plan - existing"
    And I check "Utility bill"
    And I fill in "Drawing number" with "Floorplan"
    And I press "Save"
    Then the page contains "proposed-floorplan.png has been uploaded."
    And the page contains "Date received: 5 July 2021"
    When I view the document with reference "Floorplan"
    Then the page contains "This document was manually uploaded by Morisuke"
    And I click "Edit tags"
    And the option "Floor plan - existing" is checked
    And the option "Roof plan - existing" is checked
    And the option "Utility bill" is checked
