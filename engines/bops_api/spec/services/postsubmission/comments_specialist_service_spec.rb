# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Postsubmission::CommentsSpecialistService, type: :service do
  let!(:consultation) { create(:consultation, :started) }
  let!(:consultee1) { create(:consultee, :internal, :consulted, :with_response, consultation:) }
  let!(:consultee2) { create(:consultee, :external, :consulted, :with_response, consultation:) }

  let(:scope) { Consultee::Response.all }
  let(:params) { {} } # Default empty params
  let(:service) { described_class.new(scope, params) }

  describe "#call" do
    context "when no parameters are provided" do
      it "returns all records with default sorting and pagination" do
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, scope])

        _, result = service.call

        expect(result).to eq(scope)
      end
    end

    context "when a query parameter is provided" do
      let(:params) { {query: "approved"} }

      it "filters the scope by the query" do
        filtered_scope = scope.where("redacted_response ILIKE ?", "%approved%")
        allow(scope).to receive(:where).with("redacted_response ILIKE ?", "%approved%").and_return(filtered_scope)
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, filtered_scope])

        _, result = service.call

        expect(result).to eq(filtered_scope)
      end
    end

    context "when a multiple sentiment parameter is provided" do
      let(:params) { { sentiment: ["approved", "amendmentsNeeded"] } }

      it "filters the scope by the sentiment" do
        filtered_scope = scope.where(summary_tag: ["approved", "amendments_needed"])
        allow(scope).to receive(:where).with(summary_tag: ["approved", "amendments_needed"]).and_return(filtered_scope)
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, filtered_scope])

        _, result = service.call

        expect(result).to eq(filtered_scope)
      end
    end

    context "when approved sentiment parameter is provided" do
      let(:params) { { sentiment: ["approved"] } }

      it "filters the scope by the sentiment" do
        filtered_scope = scope.where(summary_tag: ["approved"])
        allow(scope).to receive(:where).with(summary_tag: ["approved"]).and_return(filtered_scope)
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, filtered_scope])

        _, result = service.call

        expect(result).to eq(filtered_scope)
      end
    end

    context "when amendmentsNeeded sentiment parameter is provided" do
      let(:params) { { sentiment: ["amendmentsNeeded"] } }

      it "filters the scope by the sentiment" do
        filtered_scope = scope.where(summary_tag: ["amendments_needed"])
        allow(scope).to receive(:where).with(summary_tag: ["amendments_needed"]).and_return(filtered_scope)
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, filtered_scope])

        _, result = service.call

        expect(result).to eq(filtered_scope)
      end
    end

    context "when objected sentiment parameter is provided" do
      let(:params) { { sentiment: ["objected"] } }

      it "filters the scope by the sentiment" do
        filtered_scope = scope.where(summary_tag: ["objected"])
        allow(scope).to receive(:where).with(summary_tag: ["objected"]).and_return(filtered_scope)
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, filtered_scope])

        _, result = service.call

        expect(result).to eq(filtered_scope)
      end
    end

    context "when a sentiment array is provided and only one item matches" do
      let(:params) { { sentiment: ["approved", "objected"] } }
    
      it "filters the scope by the sentiment and returns results for the matching item only" do
        # Assume that only "supportive" has matching results in the scope
        matching_scope = scope.where(summary_tag: "approved")
        allow(scope).to receive(:where).with(summary_tag: ["approved", "objected"]).and_return(matching_scope)
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, matching_scope])
    
        _, result = service.call
    
        expect(result).to eq(matching_scope)
      end
    end
    context "when invalid sentiment is provided" do
      let(:params) { {sentiment: "invalidField"} }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, /Invalid sentiment field/)
      end
    end

    context "sortBy and orderBy" do
      context "when sortBy and orderBy parameters are provided" do
        let(:params) { {sortBy: "id", orderBy: "desc"} }

        it "sorts the scope by the specified field and order" do
          sorted_scope = scope.order("consultee_responses.id desc")
          allow(scope).to receive(:order).with("consultee_responses.id desc").and_return(sorted_scope)
          allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, sorted_scope])

          _, result = service.call

          expect(result).to eq(sorted_scope)
        end
      end

      context "when sortBy is provided" do
        let(:params) { {sortBy: "id", orderBy: "asc"} }

        it "sorts the scope by the specified field and order" do
          sorted_scope = scope.order("consultee_responses.id asc")
          allow(scope).to receive(:order).with("consultee_responses.id asc").and_return(sorted_scope)
          allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, sorted_scope])

          _, result = service.call

          expect(result).to eq(sorted_scope)
        end
      end

      context "when orderBy is provided" do
        let(:params) { {orderBy: "asc"} }

        it "sorts the scope by the specified field and order" do
          sorted_scope = scope.order("received_at asc")
          allow(scope).to receive(:order).with("received_at asc").and_return(sorted_scope)
          allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, sorted_scope])

          _, result = service.call

          expect(result).to eq(sorted_scope)
        end
      end
    end

    context "when invalid sortBy is provided" do
      let(:params) { {sortBy: "invalidField"} }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, /Invalid sortBy field/)
      end
    end

    context "when invalid orderBy is provided" do
      let(:params) { {orderBy: "invalidOrder"} }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, /Invalid orderBy value/)
      end
    end

    context "when pagination is applied" do
      it "calls the PostsubmissionPagination service" do
        paginated_scope = double("paginated_scope")
        allow_any_instance_of(BopsApi::Postsubmission::PostsubmissionPagination).to receive(:call).and_return([nil, paginated_scope])

        _, result = service.call

        expect(result).to eq(paginated_scope)
      end
    end
  end
end
