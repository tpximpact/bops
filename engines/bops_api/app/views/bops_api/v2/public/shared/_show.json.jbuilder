# frozen_string_literal: true

json.key_format! camelize: :lower

json.applicationType planning_application.application_type.code

json.data do 
  json.partial! "bops_api/v2/shared/postSubmissionApplication/application", planning_application: planning_application
  json.localPlanningAuthority do
    json.commentsAcceptedUntilDecision false
  end
  json.partial! "bops_api/v2/shared/postSubmissionApplication/submission", planning_application: planning_application
  if planning_application.received_at or planning_application.validated_at
    json.partial! "bops_api/v2/shared/postSubmissionApplication/validation", planning_application: planning_application
  end
  if planning_application.consultation
    json.partial! "bops_api/v2/shared/postSubmissionApplication/consultation", planning_application: planning_application
  end
  json.partial! "bops_api/v2/shared/postSubmissionApplication/assessment", planning_application: planning_application
    if (appeal = planning_application.appeal)
      json.partial! "bops_api/v2/shared/postSubmissionApplication/appeal", appeal: planning_application.appeal
  end
  json.partial! "bops_api/v2/shared/postSubmissionApplication/caseOfficer", planning_application: planning_application
end

json.partial! "bops_api/v2/shared/postSubmissionApplication/comments", planning_application: planning_application
json.submission "null"



