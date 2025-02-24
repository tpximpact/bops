      json.appeal do #condition is not obligate appeals table 
        json.reason appeal.reason # appeals.reason
        json.lodgeDate appeal.lodged_at # appeals.lodged_at
        json.validatedDate appeal.validated_at # appeals.validated_at
        json.startedDate appeal.started_at # appeals.started_at
        json.decisionDate "null"
        json.decision appeal.decision # appeals.decision
        json.withdrawnAt "null"
        json.withdrawnReason "null"
        json.documents appeal.documents #??
      end