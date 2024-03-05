# frozen_string_literal: true

json.data do
  json.description_change_validation_requests @planning_application
    .description_change_validation_requests do |description_change_validation_request|
    json.extract! description_change_validation_request,
      :id,
      :state,
      :response_due,
      :proposed_description,
      :previous_description,
      :rejection_reason,
      :approved,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "description_change_validation_request"
  end

  json.red_line_boundary_change_validation_requests @planning_application
    .red_line_boundary_change_validation_requests do |red_line_boundary_change_validation_request|
    json.extract! red_line_boundary_change_validation_request,
      :id,
      :state,
      :response_due,
      :new_geojson,
      :reason,
      :rejection_reason,
      :approved,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "red_line_boundary_change_validation_request"
  end

  json.replacement_document_validation_requests @planning_application
    .replacement_document_validation_requests do |replacement_document_validation_request|
    json.extract! replacement_document_validation_request,
      :id,
      :state,
      :response_due,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.old_document do
      json.name replacement_document_validation_request.old_document.file.filename
      json.invalid_document_reason replacement_document_validation_request.invalidated_document_reason
    end

    json.new_document do
      if replacement_document_validation_request.new_document
        json.name replacement_document_validation_request.new_document.file.filename
        json.url replacement_document_validation_request
          .new_document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      end
    end
    json.type "replacement_document_validation_request"
  end

  json.additional_document_validation_requests @planning_application
    .additional_document_validation_requests do |additional_document_validation_request|
    json.extract! additional_document_validation_request,
      :id,
      :state,
      :response_due,
      :days_until_response_due,
      :document_request_type,
      :reason,
      :cancel_reason,
      :cancelled_at

    json.documents additional_document_validation_request.additional_documents do |document|
      json.name document.file.filename
      json.url document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      json.extract! document
    end

    json.type "additional_document_validation_request"
  end

  json.fee_change_validation_requests @planning_application
    .fee_change_validation_requests do |other_change_validation_request|
    json.extract! other_change_validation_request,
      :id,
      :state,
      :response_due,
      :response,
      :reason,
      :suggestion,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "other_change_validation_request"
  end

  json.other_change_validation_requests @planning_application
    .other_change_validation_requests do |other_change_validation_request|
    json.extract! other_change_validation_request,
      :id,
      :state,
      :response_due,
      :response,
      :reason,
      :suggestion,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "other_change_validation_request"
  end

  json.ownership_certificate_validation_requests @planning_application
    .ownership_certificate_validation_requests do |ownership_certificate_validation_request|
    json.extract! ownership_certificate_validation_request,
      :id,
      :state,
      :response_due,
      :response,
      :reason,
      :suggestion,
      :reason,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "ownership_certificate_validation_request"
  end

  json.pre_commencement_condition_validation_requests @planning_application
    .pre_commencement_condition_validation_requests do |pre_commencement_condition_validation_request|
    json.extract! pre_commencement_condition_validation_request,
      :id,
      :state,
      :response_due,
      :response,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at,
      :created_at,
      :owner_id

    json.condition do
      json.title pre_commencement_condition_validation_request.owner.title
    end
    json.type "pre_commencement_condition_validation_request"
  end

  json.heads_of_terms_validation_requests @planning_application
    .heads_of_terms_validation_requests do |heads_of_terms_validation_request|
    json.extract! heads_of_terms_validation_request,
      :id,
      :state,
      :cancel_reason,
      :cancelled_at,
      :owner_id,
      :created_at

    json.term do
      json.title heads_of_terms_validation_request.owner.title
    end
    json.type "heads_of_terms_validation_request"
  end
end
