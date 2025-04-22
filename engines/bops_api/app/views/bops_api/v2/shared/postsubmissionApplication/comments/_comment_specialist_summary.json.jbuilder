# frozen_string_literal: true

json.partial! "bops_api/v2/shared/postSubmissionApplication/comments/comment_public_summary", total_responses: total_responses, response_summary: response_summary
json.totalConsulted total_consulted
json.totalComments total_responses
if response_summary.present?
  json.sentiment do
    json.approved response_summary[:approved]
    json.amendmentsNeeded response_summary[:amendments_needed]
    json.objected response_summary[:objected]
  end
end
