  json.assessment do
    # keep only council decision until we know more about committee decision
    json.councilDecision planning_application.decision
    # if(planning_application.committee_decision and planning_application.committee_decision.recommend === true)
    #    json.councilRecommendation planning_application.decision # before committee approve the recomendation will be decision after committee approves this will be committee decision
    # else json.councilDecision planning_application.decision # or decision or recommendation
    # end
    json.councilDecisionDate planning_application.determination_date 
    # if (planning_application.committee_decision)
    #   json.committeeSentDate planning_application.committee_decision.created_at
    #   json.committeeDecision planning_application.decision # if goes for a committee the decision is refused it's the same as decision see the email: /Users/gabrielamartini/Documents/bops/app/models/committee_decision.rb
    #   json.committeeDecisionDate planning_application.committee_decision.date_of_committee 
    # end
    if planning_application.decision
        json.decisionNotice do
            json.url main_app.decision_notice_api_v1_planning_application_url(planning_application, id: planning_application.reference, format: "pdf")
        end
    end
    json.priorApprovalRequired planning_application.prior_approval_required
  end