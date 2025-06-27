Feature: Editing documents for an application
  Background:
    Given I am logged in as an assessor
    And a validated planning application
    And the planning application has a document with reference "FOOBAR"
    And I view the planning application
    And I view the document with reference "FOOBAR"

  Scenario: I can replace the document
    Given I attach a replacement file with path "spec/fixtures/images/proposed-roofplan.pdf"
    And I fill in "Drawing number" with "DOC0001"
    And I check "Floor plan - existing"
    And I check "Roof plan - existing"
    And I choose "Yes" for "Do you want to list this document on the decision notice?"
    And I choose "Yes" for "Should this document be made publicly available?"
    When I press "Save"
    Then the page contains "Document has been updated"
    And the page contains "DOC0001"
    And the page contains "Included in decision notice: Yes"
    And the page contains "Public: Yes"

  Scenario: I can edit the document's received at date
    Given I set the date inputs to "19/11/2021"
    When I press "Save"
    Then the page contains "Date received: 19 November 2021"
    And there is an audit entry containing "received at date was modified"

  Scenario: I can edit and audit simultaneous updates to the document
    Given I set the date inputs to "19/11/2021"
    And I press "Save"
    And I view the document with reference "FOOBAR"
    And I set the date inputs to "22/11/2021"
    When I press "Save"
    Then there is an audit entry containing "received at date was modified"
    And there is an audit entry containing "from: 19 November 2021"
    And there is an audit entry containing "to: 22 November 2021"
