# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::SearchService do
  let(:scope) { PlanningApplication.all }
  let(:params) { {} }
  let(:service) { described_class.new(scope, params) }
  let(:pagy_and_results) { service.call }
  let(:pagy) { pagy_and_results.first }
  let(:results) { pagy_and_results.last }

  describe "call" do
    context "when page and maxresults are provided" do
      before do
        create_list(:planning_application, 25)
      end

      let(:params) { {page: 2, maxresults: 5} }

      it "paginates the results correctly" do
        expect(pagy).to have_attributes(
          page: 2,
          limit: 5,
          count: 25,
          pages: 5,
          from: 6,
          to: 10
        )
      end

      context "when exceeding the maxresults limit" do
        let(:params) { {maxresults: 50} }

        it "limits the results to MAXRESULTS_LIMIT" do
          expect(pagy.limit).to eq(BopsApi::Pagination::MAXRESULTS_LIMIT)
        end
      end
    end

    context "when performing a search" do
      let!(:matching_reference) { create(:planning_application) }
      let!(:matching_description) { create(:planning_application, description: "This is a unique description") }
      let!(:matching_address) { create(:planning_application, address_1: "123 Unique Road", county: "Greater London", town: "Unique Town", postcode: "SE21 7DN") }

      context "when searching by reference" do
        let(:params) { {q: matching_reference.reference} }

        it "returns applications matching the reference" do
          expect(results).to include(matching_reference)
          expect(results).not_to include(matching_description, matching_address)
        end
      end

      context "when searching by description" do
        let(:params) { {q: "unique description"} }

        it "returns applications matching the description" do
          expect(results).to include(matching_description)
          expect(results).not_to include(matching_reference, matching_address)
        end
      end

      context "when searching by address" do
        context "with address lines" do
          let(:params) { {q: "123 unique Road Unique town"} }

          it "returns applications matching the address" do
            expect(results).to include(matching_address)
            expect(results).not_to include(matching_reference, matching_description)
          end
        end

        context "with postcode" do
          context "with exact postcode query" do
            let(:params) { {q: "SE21 7DN"} }

            it "returns applications matching the postcode" do
              expect(results).to include(matching_address)
              expect(results).not_to include(matching_reference, matching_description)
            end
          end

          context "with postcode query" do
            let(:params) { {q: "se217Dn"} }

            it "returns applications matching the postcode" do
              expect(results).to include(matching_address)
              expect(results).not_to include(matching_reference, matching_description)
            end
          end
        end
      end

      context "when no search term matches" do
        let(:params) { {q: "noresults"} }

        it "returns no results" do
          expect(results).to be_empty
        end
      end
    end
  end
end
