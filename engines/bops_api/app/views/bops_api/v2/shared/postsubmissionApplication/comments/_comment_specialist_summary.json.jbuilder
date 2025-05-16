# frozen_string_literal: true

json.totalConsulted total_consulted
json.totalComments  total_comments

json.sentiment do
  json.approved         response_summary[:supportive]
  json.amendmentsNeeded response_summary[:neutral]
  json.objected         response_summary[:objection]
end
