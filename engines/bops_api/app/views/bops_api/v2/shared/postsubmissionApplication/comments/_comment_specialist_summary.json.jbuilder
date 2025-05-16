# frozen_string_literal: true

json.totalConsulted total_consulted
json.totalComments total_responses

json.sentiment do
  json.approved response_summary[:supportive]
  json.objection response_summary[:objection]
  json.neutral response_summary[:neutral]
end
