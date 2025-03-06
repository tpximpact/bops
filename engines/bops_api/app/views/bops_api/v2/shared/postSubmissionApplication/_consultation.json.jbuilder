  json.consultation do
    json.startDate planning_application.consultation.started_at
    json.endDate planning_application.consultation.end_date
  end