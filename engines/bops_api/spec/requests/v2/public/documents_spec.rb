# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "BOPS public API" do
  let(:config) { Rails.configuration }
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:document) { create(:document, :with_tags, validated: true, publishable: true) }
  let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, :determined, documents: [document], local_authority:, application_type:) }

  around do |example|
    travel_to("2024-10-22T10:30:00Z") { example.run }
  end

  path "/api/v2/public/planning_applications/{reference}/documents" do
    get "Retrieves documents for a planning application" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      response "200", "returns a planning application's documents and decision notice given a reference" do
        example "application/json", :default, example_fixture("documents.json")
        schema "$ref" => "#/components/schemas/Documents"

        let(:reference) { planning_application.reference }
        let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, :with_press_notice, :determined, documents: [document], local_authority:, application_type:) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(planning_application.reference)
          expect(data["decisionNotice"]["name"]).to eq("decision-notice-PlanX-24-00100-HAPP.pdf")
          expect(data["decisionNotice"]["url"]).to eq("http://planx.bops.services/api/v1/planning_applications/#{planning_application.reference}/decision_notice.pdf")

          expect(data["files"]).to match_array([
            a_hash_including("url" => "http://planx.bops.services/files/#{document.blob_key}")
          ])
        end
      end

      it "validates successfully against the example documents json" do
        resolved_schema = load_and_resolve_schema(name: "documents", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("documents.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end
    end
  end

  context "when there is a site_notice" do
    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: "2024-01-08T09:00:00Z",
        expiry_date: "2024-01-30",
        internal_team_email: "pressteam@example.com")
    end

    let!(:site_notice_evidence) do
      create(:document,
        :public,
        numbers: "siteNotice2025v2",
        planning_application: planning_application,
        owner: site_notice,
        file: fixture_file_upload("site-notice.jpg", "image/jpeg", true),
        tags: ["internal.siteNotice"])
    end

    path "/api/v2/public/planning_applications/{reference}/documents" do
      get "Retrieves documents for a planning application" do
        tags "Planning applications"
        produces "application/json"

        parameter name: :reference, in: :path, schema: {
          type: :string,
          description: "The planning application reference"
        }

        response "200", "returns a non determined planning application's documents given a reference" do
          example "application/json", :default, example_fixture("documents.json")
          schema "$ref" => "#/components/schemas/Documents"

          let(:reference) { planning_application.reference }
          let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, decision: "refused", documents: [document], local_authority:, application_type:) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["application"]["reference"]).to eq(planning_application.reference)
            # Decision notice should not be present for non determined applications
            expect(data["decisionNotice"]).to be_nil

            expect(data["files"]).to match_array([
              a_hash_including("url" => "http://planx.bops.services/files/#{document.blob_key}"),
              a_hash_including(
                "name" => "site-notice.jpg",
                "referencesInDocument" => ["siteNotice2025v2"],
                "url" => "http://planx.bops.services/files/#{site_notice_evidence.blob_key}",
                "type" => [
                  a_hash_including(
                    "description" => "Site Notice",
                    "value" => "internal.siteNotice"
                  )
                ]
              )
            ])
          end
        end

        response "200", "returns a planning application's documents and decision notice given a reference" do
          example "application/json", :default, example_fixture("documents.json")
          schema "$ref" => "#/components/schemas/Documents"

          let(:reference) { planning_application.reference }
          let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, :determined, documents: [document], local_authority:, application_type:) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["application"]["reference"]).to eq(planning_application.reference)
            expect(data["decisionNotice"]).to eq(
              "name" => "decision-notice-#{planning_application.reference_in_full}.pdf",
              "url" => "http://planx.bops.services/api/v1/planning_applications/#{planning_application.reference}/decision_notice.pdf"
            )

            expect(data["files"]).to match_array([
              a_hash_including("url" => "http://planx.bops.services/files/#{document.blob_key}"),
              a_hash_including(
                "name" => "site-notice.jpg",
                "referencesInDocument" => ["siteNotice2025v2"],
                "url" => "http://planx.bops.services/files/#{site_notice_evidence.blob_key}",
                "type" => [
                  a_hash_including(
                    "description" => "Site Notice",
                    "value" => "internal.siteNotice"
                  )
                ]
              )
            ])
          end
        end
      end
    end
  end
end
