# frozen_string_literal: true

require "rails_helper"

RSpec.describe PressNotice do
  describe "validations" do
    subject(:press_notice) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { press_notice.valid? }.to change { press_notice.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#required" do
      it "validates inclusion in [true, false]" do
        expect { press_notice.valid? }.to change { press_notice.errors[:required] }.to ["Choose 'Yes' or 'No'"]
      end
    end

    describe "#reasons" do
      context "when required is 'true'" do
        subject(:press_notice) { described_class.new(required: true) }

        it "validates presence" do
          expect { press_notice.valid? }.to change { press_notice.errors[:reasons] }.to ["Provide a reason for the press notice"]
        end
      end

      context "when required is 'false'" do
        subject(:press_notice) { described_class.new(required: false) }

        it "does not validate presence" do
          expect { press_notice.valid? }.not_to(change { press_notice.errors[:reasons] })
        end
      end
    end

    describe "callbacks" do
      describe "::before_create #ensure_publicity_feature!" do
        context "when the application type enables publicity" do
          let(:application_type) { create(:application_type, :planning_permission) }
          let(:planning_application) { create(:planning_application, application_type:) }
          let(:press_notice) { create(:press_notice, planning_application:) }

          it "allows a press notice to be created" do
            expect do
              press_notice
            end.not_to raise_error(described_class::NotCreatableError)
          end
        end

        context "when the application type does not enable publicity" do
          let(:application_type) { create(:application_type, :without_consultation) }
          let(:planning_application) { create(:planning_application, application_type:) }
          let(:press_notice) { create(:press_notice, planning_application:) }

          it "allows a press notice to be created" do
            expect do
              press_notice
            end.to raise_error(described_class::NotCreatableError,
              "Cannot create press notice when application type does not permit this feature.")
          end
        end
      end

      describe "::after_save #audit_press_notice!" do
        let(:default_local_authority) { create(:local_authority, :default) }
        let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
        let!(:planning_application) { create(:planning_application, :planning_permission, local_authority: default_local_authority) }

        before do
          Current.user = assessor
        end

        context "when press notice marked as required" do
          let(:press_notice) { create(:press_notice, :required, planning_application:) }

          it "adds an audit entry with the reasons when creating the press notice response" do
            expect do
              press_notice
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as required with the following reasons: environment, development_plan",
              user: assessor
            )
          end

          it "adds an audit entry with the reasons when updating the press notice response" do
            press_notice

            expect do
              press_notice.update!(reasons: %w[ancient_monument])
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: press_notice.planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as required with the following reasons: ancient_monument",
              user: assessor
            )
          end
        end

        context "when press notice marked as not required" do
          let(:press_notice) { create(:press_notice, planning_application:) }

          it "adds an audit entry when creating the press notice response" do
            expect do
              press_notice
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as not required",
              user: assessor
            )
          end
        end
      end

      describe "::after_update #extend_consultation!" do
        let(:default_local_authority) { create(:local_authority, :default) }
        let!(:planning_application) { create(:planning_application, :planning_permission, local_authority: default_local_authority) }
        let!(:consultation) { planning_application.consultation }
        let(:press_notice) { create(:press_notice, planning_application:) }

        context "when there is an update to the published_at date" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update of 21 days added to the consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 5, 23).to_date)
          end

          it "sets the expiry date to the new consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(press_notice, :expiry_date)
              .from(nil)
              .to(Time.zone.local(2023, 4, 5, 23).to_date)
          end
        end

        context "when there is an update to another field" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is no update to the consultation end date" do
            expect { press_notice.update(requested_at: Time.zone.local(2023, 3, 15)) }.not_to change(consultation, :end_date)
          end

          it "does not update the expiry date" do
            expect { press_notice.update(requested_at: Time.zone.local(2023, 3, 15)) }.not_to change(press_notice, :expiry_date).from(nil)
          end
        end

        context "when consultation end date is later than the published at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 4, 10, 23, 59, 59, 999999)
            )
          end

          it "there is no update to the consultation end date" do
            expect { press_notice.update(published_at: Time.zone.local(2023, 3, 15)) }.not_to change(consultation, :end_date)
          end

          it "sets the expiry date to the existing consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(press_notice, :expiry_date)
              .from(nil)
              .to(consultation.end_date)
          end
        end

        context "when consultation end date is less than the published at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update to the consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 5).to_date)
          end

          it "sets the expiry date to the new consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(press_notice, :expiry_date)
              .from(nil)
              .to(Time.zone.local(2023, 4, 5).to_date)
          end
        end

        context "when application has been marked as requiring an EIA and there is an update to the published_at date" do
          let!(:environment_impact_assessment) { create(:environment_impact_assessment, planning_application:) }

          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update of 30 days added to the consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 14).to_date)
          end

          it "sets the expiry date to the new consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(press_notice, :expiry_date)
              .from(nil)
              .to(Time.zone.local(2023, 4, 14).to_date)
          end
        end
      end
    end
  end
end
