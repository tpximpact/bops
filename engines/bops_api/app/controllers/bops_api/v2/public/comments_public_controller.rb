# frozen_string_literal: true

module BopsApi
    module V2
        module Public
            class CommentsPublicController < PublicController
                def show
                    @pagy, @responses = query_service.call

                    respond_to do |format|
                    format.json
                    end
                end

                private

                def response_scope
                    current_local_authority.neighbour_responses
                        .joins(neighbour: { consultation: :planning_application })
                        .where(planning_applications: { reference: params[:planning_application_id] })
                        .select(:id, :redacted_response, :received_at, :summary_tag)
                end
                def search_params
                    params.permit(:page, :query, :sortBy, :orderBy, :resultsPerPage)
                end
                def query_service(scope = response_scope)
                    @query_service ||= Comment::QueryPublicService.new(scope, search_params)
                end
            end
        end
    end
end