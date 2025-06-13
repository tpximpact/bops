# frozen_string_literal: true

json.metadata do
  json.resultsPerPage @pagy.limit
  json.currentPage    @pagy.page
  json.totalPages     @pagy.pages
  json.totalResults   @pagy.count
end
json.links pagy_jsonapi_links(@pagy, absolute: true)

json.data @planning_applications do |planning_application|
  json.partial! "bops_api/v2/public/shared/show", planning_application: planning_application
  json.partial! "bops_api/v2/shared/postsubmissionApplication/postsubmissionApplication", planning_application: planning_application
end
