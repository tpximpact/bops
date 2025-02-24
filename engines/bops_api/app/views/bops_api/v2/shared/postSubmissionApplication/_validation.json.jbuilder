  json.validation do #condition is not obligate 
    json.receivedAt planning_application.received_at
    json.validatedAt planning_application.validated_at
    json.isValid "null" #This determines whether or not an application was found to be valid
  end