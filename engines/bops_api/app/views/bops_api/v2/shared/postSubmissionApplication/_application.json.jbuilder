json.application do #check ApplicationVariant
    json.reference planning_application.reference
    json.stage "null" #?? current stage of application  | submission | validation | consultation | assessment | appeal | highCourtAppeal;
    json.status planning_application.status #tobe confirm | returned | withdrawn | determined | undetermined;
    json.withdrawnAt planning_application.withdrawn_at
    # json.withdrawnReason planning_application.withdrawn_or_cancellation_comment
  end