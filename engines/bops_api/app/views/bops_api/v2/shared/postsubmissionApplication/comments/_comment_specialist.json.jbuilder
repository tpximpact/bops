# frozen_string_literal: true

grouped_specialists = @comments
  .group_by(&:consultee_id)
  .reject { |consultee_id, _| consultee_id.nil? }

json.specialists do
  grouped_specialists.each do |consultee_id, responses|
    consultee = responses.first.consultee
    active_constraints = consultee.planning_application_constraints.active

    json.child! do
      # Consultee Details
      json.id consultee.id.to_s
      json.organisationSpecialism consultee.organisation if consultee.organisation.present?
      json.jobTitle consultee.role if consultee.role.present?

      # Determine Reason for Consultation
      first_active_constraint = active_constraints.first
      reason_type_code = first_active_constraint&.constraint&.type_code
      json.reason reason_type_code.present? ? "Constraint" : "Other"

      # Constraints Information
      if active_constraints.any?
        json.constraints active_constraints do |planning_app_constraint|
          # Skip if the constraint itself is missing
          next unless planning_app_constraint.constraint
          constraint = planning_app_constraint.constraint

          json.child! do
            json.value constraint.type
            json.category constraint.category
            json.description constraint.type_code
            json.intersects planning_app_constraint.identified?

            # Include entities if present. Only including name for now but will expand to show source
            if planning_app_constraint.data&.any?
              json.entities planning_app_constraint.data do |item|
                json.name item["name"]
              end
            end
          end
        end
      end

      json.firstConsultedAt format_postsubmission_datetime(consultee.email_sent_at) if consultee.email_sent_at

      # Comments
      json.comments responses do |resp|
        json.id resp.id.to_s
        json.sentiment resp.summary_tag.camelize(:lower)
        json.commentRedacted resp.redacted_response

        if resp.documents.any?
          json.files resp.documents do |document|
            json.id document.id
            json.name document.file_attachment.filename
            json.association "comment"
            json.type document.file_attachment.content_type
            json.url document.blob_url

            json.metadata do
              json.size do
                json.bytes document.file_attachment.blob.byte_size
              end
              json.mimeType document.file_attachment.blob.content_type
              json.createdAt format_postsubmission_datetime(document.created_at)
              json.submittedAt format_postsubmission_datetime(document.received_at)
            end
          end
        end

        json.metadata do
          json.submittedAt format_postsubmission_datetime(resp.created_at)
          # json.validatedAt format_postsubmission_datetime(resp.redacted_at)
          json.publishedAt format_postsubmission_datetime(resp.updated_at)
        end
      end
    end
  end
end

# SpecialistComment

# json.id comment.id
# json.sentiment comment.summary_tag
# json.comment comment.redacted_response
# json.constraints "PlanningConstraint[]"
# json.reason "string"
# json.comment "string"
# json.author "SpecialistCommentAuthor"
# json.consultedAt "DateTime"
# json.respondedAt "DateTime"
# json.files "PostSubmissionFile[]"
# json.responses "SpecialistComment[]"

# json.author do
#   json.name do
#     json.singleLine comment.name
#   end
# #   json.organisation "string;"
# #   json.specialism "string;"
# #   json.jobTitle "string;"
# end

# json.metadata do
#   json.submittedAt format_postsubmission_datetime(comment.created_at)
#   # json.publishedAt format_postsubmission_datetime(comment.received_at)
#   json.validAt format_postsubmission_datetime(comment.updated_at)
# end
