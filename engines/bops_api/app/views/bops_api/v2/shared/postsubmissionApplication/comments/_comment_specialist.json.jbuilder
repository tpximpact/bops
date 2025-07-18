# frozen_string_literal: true

grouped = @comments
  .group_by(&:consultee_id)
  .reject { |consultee_id, _| consultee_id.nil? }

json.specialists do
  grouped.each do |consultee_id, responses|
    consultee = responses.first.consultee
    active_constraints = consultee.planning_application_constraints.active
    first_pac = active_constraints.first
    reason_type_code = first_pac&.constraint&.type_code

    json.child! do
      json.id consultee.id.to_s
      json.organisationSpecialism consultee.organisation
      json.jobTitle consultee.role
      json.reason reason_type_code.present? ? "Constraint" : "Other"

      if active_constraints.any?
        json.constraints active_constraints do |planning_app_constraint|
          next unless planning_app_constraint.constraint
          constraint = planning_app_constraint.constraint

          json.child! do
            json.value constraint.type
            json.category constraint.category
            json.description constraint.type_code
            json.intersects planning_app_constraint.identified?

            if planning_app_constraint.data&.any?
              json.entities planning_app_constraint.data do |item|
                json.name item["name"]
              end
            end
          end
        end
      end

      json.set! :firstConsultedAt, format_postsubmission_datetime(consultee.email_sent_at)

      json.comments responses
        .sort_by(&:id)
        .reverse do |resp|
          json.id resp.id.to_s
          json.sentiment resp.summary_tag.camelize(:lower)
          json.commentRedacted resp.redacted_response

          json.metadata do
            json.submittedAt format_postsubmission_datetime(resp.received_at)
            json.validatedAt format_postsubmission_datetime(resp.redacted_at)
            json.publishedAt format_postsubmission_datetime(resp.redacted_at)
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
