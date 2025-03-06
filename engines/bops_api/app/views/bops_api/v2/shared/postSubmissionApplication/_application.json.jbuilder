json.application do 
    json.reference planning_application.reference
    json.stage planning_application.planning_stage
    json.status planning_application.planning_status
    json.withdrawnAt planning_application.withdrawn_at
    json.withdrawnReason "null"
  end