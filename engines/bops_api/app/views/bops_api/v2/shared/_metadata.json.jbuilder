# frozen_string_literal: true

json.metadata do
  json.page @pagy.page
  json.results @pagy.limit
  json.from @pagy.from
  json.to @pagy.to
  json.total_pages @pagy.pages
  json.total_results @pagy.count
end

json.links pagy_jsonapi_links(@pagy, absolute: true)
