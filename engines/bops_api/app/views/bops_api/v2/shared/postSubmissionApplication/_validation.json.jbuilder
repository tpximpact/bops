  json.validation do #condition is not obligate 
    json.receivedAt planning_application.received_at
    json.validatedAt planning_application.validated_at
    json.isValid planning_application.is_valid_application
  end