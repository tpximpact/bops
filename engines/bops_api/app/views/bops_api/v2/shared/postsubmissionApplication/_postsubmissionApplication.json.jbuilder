# frozen_string_literal: true

json.debug do
  json.generatedFrom 'jbuilder'
  json.determined planning_application.determined?
  json.status planning_application.status
end

json.applicationType planning_application.applicationType

json.data do
  json.application do
    json.reference planning_application.application.reference
    json.stage planning_application.application.stage
    json.status planning_application.application.status
    json.withdrawnAt format_postsubmission_datetime(planning_application.application.withdrawnAt) if planning_application.application.withdrawnAt
    json.withdrawnReason planning_application.application.withdrawnReason if planning_application.application.withdrawnReason
    json.publishedAt format_postsubmission_datetime(planning_application.application.publishedAt) if planning_application.application.publishedAt
  end
  json.submission do
    json.submittedAt planning_application.submission.submittedAt
  end
  json.localPlanningAuthority do
    json.publicCommentsAcceptedUntilDecision planning_application.localPlanningAuthority.publicCommentsAcceptedUntilDecision
  end
  json.validation do
    json.receivedAt format_postsubmission_datetime(planning_application.validation.receivedAt)
    json.validatedAt format_postsubmission_datetime(planning_application.validation.validatedAt) if planning_application.validation.validatedAt
    json.isValid planning_application.validation.isValid
  end
  json.consultation do
    json.startDate format_postsubmission_date(planning_application.consultation.startDate)
    json.endDate format_postsubmission_date(planning_application.consultation.endDate)
    json.siteNotice planning_application.consultation.siteNotice
    json.pressNotice planning_application.consultation.pressNotice
  end if planning_application.consultation
  json.assessment do
    json.expiryDate format_postsubmission_date(planning_application.assessment.expiryDate)
    json.decisionNotice do
      json.url planning_application.assessment.decisionNotice[:url] if planning_application.assessment.decisionNotice[:url]
    end if planning_application.assessment.decisionNotice
    # AssessmentDecisionSection
    json.planningOfficerDecision planning_application.assessment.planningOfficerDecision if planning_application.assessment.planningOfficerDecision
    json.planningOfficerDecisionDate format_postsubmission_date(planning_application.assessment.planningOfficerDecisionDate) if planning_application.assessment.planningOfficerDecisionDate
    # AssessmentCommittee
    json.planningOfficerRecommendation planning_application.assessment.planningOfficerRecommendation if planning_application.assessment.planningOfficerRecommendation
    json.committeeSentDate format_postsubmission_date(planning_application.assessment.committeeSentDate) if planning_application.assessment.committeeSentDate
    json.committeeDecision planning_application.assessment.committeeDecision if planning_application.assessment.committeeDecision
    json.committeeDecisionDate format_postsubmission_date(planning_application.assessment.committeeDecisionDate) if planning_application.assessment.committeeDecisionDate
    # PriorApprovalAssessment
    json.priorApprovalRequired planning_application.assessment.priorApprovalRequired if planning_application.assessment.priorApprovalRequired
  end if planning_application.assessment
  json.appeal do
    json.reason planning_application.appeal.reason if planning_application.appeal.reason

    json.lodgedDate format_postsubmission_date(planning_application.appeal.lodgedDate) if planning_application.appeal.lodgedDate
    json.validatedDate format_postsubmission_date(planning_application.appeal.validatedDate) if planning_application.appeal.validatedDate
    json.startedDate format_postsubmission_date(planning_application.appeal.startedDate) if planning_application.appeal.startedDate

    json.decisionDate format_postsubmission_date(planning_application.appeal.decisionDate) if planning_application.appeal.decisionDate
    json.decision planning_application.appeal.decision if planning_application.appeal.decision

    if planning_application.appeal.files
      json.files planning_application.appeal.files do |file|
        json.partial! "bops_api/v2/shared/postsubmissionApplication/data/postsubmission_file", planning_application: @planning_application, file:
      end
    end
  end if planning_application.appeal
  json.caseOfficer do
    json.name planning_application.caseOfficer.name
  end
end

json.submission planning_application.originalSubmission 


json.metadata do
  json.organisation planning_application.metadata.organisation
  json.id planning_application.metadata.id
  json.submittedAt format_postsubmission_datetime(planning_application.metadata.submittedAt)
  json.schema planning_application.metadata.schema
  json.generatedAt format_postsubmission_datetime(planning_application.metadata.generatedAt)
end




# #   json.application ''
# #   json.localPlanningAuthority ''
# #   json.submission ''
# #   json.validation ''
# #   json.consultation ''
# #   json.assessment ''
  # 

# json.comments do
#   json.public ''
#   json.specialist ''
# end

# json.submission planning_application.params_v2

# json.files planning_application.documents do |file|
#   json.partial! "bops_api/v2/shared/postsubmissionApplication/types/postsubmission_file", planning_application: @planning_application, file:
# end








