# frozen_string_literal: true

  json.id response.id
  json.text response.redacted_response.presence
  json.sentiment response.summary_tag

  json.extract! response,
  :received_at