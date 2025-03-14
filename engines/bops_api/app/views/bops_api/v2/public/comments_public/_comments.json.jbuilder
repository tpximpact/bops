# frozen_string_literal: true

  json.id response.id
  json.comment response.redacted_response.presence
  json.sentiment response.summary_tag
  json.receivedAt response.received_at