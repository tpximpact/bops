  json.assessment do #condition is not obligate 
    # condition is it's priorApprovalRequired or the rest
    json.councilDecision planning_application.decision
    json.councilDecisionDate planning_application.determination_date #tobe confirmed
    json.councilRecommendation planning_application.recommendation
    json.committeeSentDate "null"
    json.committeeDecision planning_application.committee_decision
    json.committeeDecisionDate "null"
    # json.decisionNotice planning_application.decision_notice
    json.priorApprovalRequired "null"
  end