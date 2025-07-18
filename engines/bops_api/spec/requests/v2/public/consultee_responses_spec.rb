# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "BOPS public API Specialist comments" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

  context "when every consulted consultee has exactly one redacted response" do
    before do
      create_list(:consultee, 50, :consulted, consultation: planning_application.consultation).each_with_index do |consultee, i|
        create(:consultee_response, :with_redaction, id: 1000 + i, consultee: consultee, received_at: (i + 1).hours.ago)
      end
      create_list(:consultee, 50, consultation: planning_application.consultation)
    end

    path "/api/v2/public/planning_applications/{reference}/comments/specialist" do
      get "Retrieves comments for a planning application" do
        tags "Planning applications"
        produces "application/json"

        parameter name: :reference, in: :path, schema: {
          type: :string,
          description: "The planning application reference"
        }

        parameter name: :sortBy, in: :query, schema: {
          type: :string,
          enum: ["id", "receivedAt"],
          default: "receivedAt",
          description: "The sort type for the comments"
        }, required: false

        parameter name: :orderBy, in: :query, schema: {
          type: :string,
          enum: ["asc", "desc"],
          default: "desc",
          description: "The order for the comments"
        }, required: false

        parameter name: :resultsPerPage, in: :query, schema: {
          type: :integer,
          default: 10,
          description: "Max result for page"
        }, required: false

        parameter name: :page, in: :query, schema: {
          type: :integer,
          default: 1
        }, required: false

        parameter name: :query, in: :query, schema: {
          type: :string,
          description: "Search by redacted comment content"
        }, required: false

        def validate_pagination(data, results_per_page:, current_page:, total_results:, total_available_items:)
          expect(data["pagination"]["resultsPerPage"]).to eq(results_per_page)
          expect(data["pagination"]["totalPages"]).to eq((total_results.to_f / results_per_page).ceil)
          expect(data["pagination"]["totalResults"]).to eq(total_results)
          expect(data["pagination"]["totalAvailableItems"]).to eq(total_available_items)
        end

        def validate_comment_summary(data, total_comments: 50, total_consulted: 50)
          expect(data["summary"]["totalComments"]).to eq(total_comments)
          expect(data["summary"]["totalConsulted"]).to eq(total_consulted)
          sentiment = data.dig("summary", "sentiment")
          expect(sentiment["approved"]).to eq(total_comments)
          expect(sentiment["objected"]).to eq(0)
          expect(sentiment["amendmentsNeeded"]).to eq(0)
        end

        def validate_comments(data, specialist_count:)
          specialists = data.dig("comments", "specialists")
          expect(specialists).to be_an(Array)
          expect(specialists.size).to eq(specialist_count)
          specialists.each do |s|
            expect(s["comments"].first["commentRedacted"]).to include("*****")
            expect { DateTime.iso8601(s["firstConsultedAt"]) }.not_to raise_error
          end
        end

        response "200", "returns a planning application's specialist comments given a reference" do
          example "application/json", :default, example_fixture("public/comments_specialist.json")
          schema "$ref" => "#/components/schemas/CommentsSpecialistResponse"

          let(:reference) { planning_application.reference }

          run_test! do |response|
            data = JSON.parse(response.body)
            validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 50, total_available_items: 50)
            validate_comment_summary(data)
            validate_comments(data, specialist_count: 10)
          end
        end

        response "200", "returns planning application's specialist comments paginated given a page and resultsPerPage param" do
          let(:reference) { planning_application.reference }
          let(:page) { 2 }
          let(:resultsPerPage) { 5 }

          run_test! do |response|
            data = JSON.parse(response.body)
            validate_pagination(data, results_per_page: 5, current_page: 2, total_results: 50, total_available_items: 50)
            validate_comment_summary(data)
            validate_comments(data, specialist_count: 5)
          end
        end

        response "200", "returns a planning application's specialist comments filtering by query" do
          before do
            create(:consultee, :external, :consulted, consultation: planning_application.consultation, organisation: "External Company") do |consultee|
              create(:consultee_response, :with_redaction, consultee: consultee, redacted_response: "***** not like the other comments")
            end
          end
          let(:reference) { planning_application.reference }
          let(:query) { "not like the other comments" }

          run_test! do |response|
            data = JSON.parse(response.body)
            validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 1, total_available_items: 51)
            validate_comment_summary(data, total_comments: 51, total_consulted: 51)
            validate_comments(data, specialist_count: 1)
            expect(data.dig("comments", "specialists").first["organisationSpecialism"]).to eq("External Company")
          end
        end

        context "when sorting specialist comments" do
          let(:reference) { planning_application.reference }

          shared_examples "sortBy and orderBy validation" do |sort_by_val, order_by_val, field_to_check|
            let(:sortBy) { sort_by_val }
            let(:orderBy) { order_by_val }

            run_test! do |response|
              data = JSON.parse(response.body)
              specialists = data.dig("comments", "specialists")

              sorted_values = if field_to_check == :receivedAt
                specialists.map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
              else
                specialists.map { |s| s["comments"].first[field_to_check.to_s] }
              end

              expected_order = (order_by_val == "asc") ? sorted_values.sort : sorted_values.sort.reverse
              expect(sorted_values).to eq(expected_order)
            end
          end

          response "200", "sorts by receivedAt descending by default" do
            it_behaves_like "sortBy and orderBy validation", nil, "desc", :receivedAt
          end

          context "sortBy is id" do
            response "200", "sorts by id ascending" do
              it_behaves_like "sortBy and orderBy validation", "id", "asc", "id"
            end

            response "200", "sorts by id descending" do
              it_behaves_like "sortBy and orderBy validation", "id", "desc", "id"
            end
          end

          context "sortBy is receivedAt" do
            response "200", "sorts by receivedAt ascending" do
              it_behaves_like "sortBy and orderBy validation", "receivedAt", "asc", :receivedAt
            end
            response "200", "sorts by receivedAt descending" do
              it_behaves_like "sortBy and orderBy validation", "receivedAt", "desc", :receivedAt
            end
          end

          context "only sortBy is set" do
            response "200", "when sortBy is receivedAt, it defaults to desc" do
              let(:sortBy) { "receivedAt" }
              run_test! do |response|
                data = JSON.parse(response.body)
                specialists = data.dig("comments", "specialists")
                sorted_values = specialists.map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
                expect(sorted_values).to eq(sorted_values.sort.reverse)
              end
            end

            response "200", "when sortBy is id, it defaults to asc" do
              let(:sortBy) { "id" }
              run_test! do |response|
                data = JSON.parse(response.body)
                specialists = data.dig("comments", "specialists")
                sorted_values = specialists.map { |s| s["comments"].first["id"] }
                expect(sorted_values).to eq(sorted_values.sort)
              end
            end
          end

          context "only orderBy is set" do
            response "200", "when orderBy is asc, it defaults to receivedAt" do
              let(:orderBy) { "asc" }
              run_test! do |response|
                data = JSON.parse(response.body)
                specialists = data.dig("comments", "specialists")
                sorted_values = specialists.map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
                expect(sorted_values).to eq(sorted_values.sort)
              end
            end

            response "200", "when orderBy is desc, it defaults to receivedAt" do
              let(:orderBy) { "desc" }
              run_test! do |response|
                data = JSON.parse(response.body)
                specialists = data.dig("comments", "specialists")
                sorted_values = specialists.map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
                expect(sorted_values).to eq(sorted_values.sort.reverse)
              end
            end
          end
        end

        response "404", "does not return comments for unpublished planning applications" do
          let(:reference) { planning_application.reference }
          let(:planning_application) { create(:planning_application, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]["message"]).to eq("Not Found")
          end
        end

        # it "validates successfully against the example comments_specialist json" do
        #   resolved_schema = load_and_resolve_schema(name: "comments_specialist", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        #   schemer = JSONSchemer.schema(resolved_schema)
        #   example_json = example_fixture("public/comments_specialist.json")

        #   expect(schemer.valid?(example_json)).to eq(true)
        # end
      end
    end
  end

  context "when some consultees have no redacted responses or multiple redactions" do
    path "/api/v2/public/planning_applications/{reference}/comments/specialist" do
      get "Edge-case scenarios" do
        tags "Planning applications"
        produces "application/json"
        parameter name: :reference, in: :path, schema: {type: :string}

        response "200", "no redacted responses gives a count of zero" do
          before do
            create_list(:consultee, 2, :consulted, :with_response, consultation: planning_application.consultation)
          end
          let(:reference) { planning_application.reference }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["summary"]["totalConsulted"]).to eq(2)
            expect(data["summary"]["totalComments"]).to eq(0)
            expect(data.dig("comments", "specialists") || []).to be_empty
          end
        end

        response "200", "only consultees with redacted responses are counted" do
          before do
            create(:consultee, :consulted, consultation: planning_application.consultation) do |c|
              create(:consultee_response, :with_redaction, consultee: c)
            end
            create(:consultee, :consulted, :with_response, consultation: planning_application.consultation)
          end
          let(:reference) { planning_application.reference }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["summary"]["totalConsulted"]).to eq(2)
            expect(data["summary"]["totalComments"]).to eq(1)
            expect(data.dig("comments", "specialists").size).to eq(1)
          end
        end

        response "200", "latest response only for multiple redacted comments" do
          let!(:consultee) { create(:consultee, :consulted, consultation: planning_application.consultation) }
          before do
            create(:consultee_response, :with_redaction, consultee: consultee, summary_tag: "objected", received_at: 2.days.ago)
            create(:consultee_response, :with_redaction, consultee: consultee, summary_tag: "approved", received_at: 1.hour.ago)
          end
          let(:reference) { planning_application.reference }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["summary"]["totalConsulted"]).to eq(1)
            expect(data["summary"]["totalComments"]).to eq(1)
            expect(data["summary"]["sentiment"]["approved"]).to eq(1)
            expect(data["summary"]["sentiment"]["objected"]).to eq(0)

            specialist = data.dig("comments", "specialists").first
            expect(specialist["comments"].size).to eq(2)
            sentiments = specialist["comments"].pluck("sentiment")
            expect(sentiments).to contain_exactly("approved", "objected")
          end
        end
      end
    end
  end
end
