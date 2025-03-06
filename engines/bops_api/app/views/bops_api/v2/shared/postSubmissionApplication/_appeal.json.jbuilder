      json.appeal do 
        json.reason appeal.reason 
        json.lodgeDate appeal.lodged_at
        json.validatedDate appeal.validated_at
        json.startedDate appeal.started_at
        json.decisionDate appeal.determined_at
        json.decision appeal.decision
        json.withdrawnAt "null"
        json.withdrawnReason "null"
        json.documents appeal.documents # should we show???
      end