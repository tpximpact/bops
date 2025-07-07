# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class PlanningApplicationPresenter
      delegate :reference, :determined?, :status, to: :@planning_application

      def initialize(planning_application)
        @planning_application = planning_application
      end

      def applicationType
        @planning_application.application_type&.code
      end

      def application
        Application.new(@planning_application)
      end

      def submission
        Submission.new(@planning_application)
      end

      def validation
        Validation.new(@planning_application)
      end

      def consultation
        consultation = @planning_application.consultation
        return nil if consultation.blank? || (consultation.start_date.blank? && consultation.end_date.blank?)
        Consultation.new(@planning_application)
      end

      def assessment
        Assessment.new(@planning_application) 
      end
      
      def appeal
        Appeal.new(@planning_application) if @planning_application.appeal.present?
      end

      def caseOfficer
        CaseOfficer.new(@planning_application)
      end

      def localPlanningAuthority
        LocalPlanningAuthority.new(@planning_application)
      end

      def originalSubmission
        OriginalSubmission.new(@planning_application)
      end

      def metadata
        Metadata.new(@planning_application, submission.submittedAt)
      end

      def as_json(*)
        data_hash = {
          generatedFrom: 'presenter',
          determined: @planning_application.determined?,
          status: @planning_application.status,
          applicationType: applicationType,
          data: {
            application: application.as_json,
            submission: submission.as_json,
            localPlanningAuthority: localPlanningAuthority.as_json,
            caseOfficer: caseOfficer.as_json,
          },
          submission: originalSubmission.as_json,
          metadata: metadata.as_json,
          test: @planning_application.application_type.name
        }
         
        data_hash[:data][:appeal] = appeal.as_json if appeal
        data_hash[:data][:validation] = validation.as_json if validation
        data_hash[:data][:consultation] = consultation.as_json if consultation
        data_hash[:data][:assessment] = assessment.as_json if assessment

        data_hash
      end

      private

      class Application
        include BopsApi::PostsubmissionApplicationSchemaHelper
        attr_reader :reference, :stage, :status, :withdrawnAt, :withdrawnReason, :publishedAt

        def initialize(planning_application)
          @reference = planning_application.reference
          @stage = get_stage(planning_application)
          @status = get_status(planning_application)
          @withdrawnAt = planning_application.withdrawn_at
          # TODO
          @withdrawnReason = nil
          @publishedAt = planning_application.published_at
        end

        def as_json(*)
          data = {
            reference: @reference,
            stage: @stage,
            status: @status,
          }

          data[:withdrawnAt] = format_postsubmission_datetime(@withdrawnAt) if @withdrawnAt.present?
          data[:withdrawnReason] = @withdrawnReason if @withdrawnReason.present?
          data[:publishedAt] = format_postsubmission_datetime(@publishedAt) if @publishedAt.present?
          
          data
        end

        private

        # TODO map these more accurately
        # possible values undetermined, returned, withdrawn, determined
        def get_status(planning_application)
          # planning_application.appeal_display_status || planning_application.status
          case planning_application.status
          when 'pending' 'not_started'
            'undetermined'
          when 'invalidated'
            'returned'
          when 'assessment_in_progress' 'awaiting_determination' 'in_committee' 'to_be_reviewed' 'determined'
            'determined'
          when 'returned'
            'returned'
          when 'withdrawn'
            'withdrawn'
          when 'closed'
            'undetermined'
          else 
            'undetermined'
          end 
        end

        # TODO map these more accurately
        # possible values submission, validation, consultation, assessment, appeal, highCourtAppeal
        def get_stage(planning_application)

          # valid applications can only be:  consultation, assessment, appeal, highCourtAppeal
          if planning_application.validated?
            planning_application&.consultation&.status == 'in_progress' ? 'consultation' : 'assessment' 

            if planning_application.appeal.present?
              return 'appeal'
            end
          else 
          # invalid applications can only be: submission, validation
            if planning_application.validated_at
              return 'validation'
            else
              return 'submission'
            end
          end



        end
      end

      class Submission
        include BopsApi::PostsubmissionApplicationSchemaHelper
        attr_reader :submittedAt

        def initialize(planning_application)
          @submittedAt = get_submittedAt(planning_application)
        end

        def as_json(*)
          {
            submittedAt: format_postsubmission_datetime(@submittedAt)
          }
        end

        private

        def get_submittedAt(planning_application)
          submitted_at_str = planning_application.params_v2&.dig(:metadata, :submittedAt)
          if submitted_at_str.present?
            Time.zone.parse(submitted_at_str)&.utc
          elsif planning_application.created_at.present?
            planning_application.created_at&.utc
          else
            raise "Cannot convert: submittedAt is missing"
          end
        end
      end

      class Validation
        include BopsApi::PostsubmissionApplicationSchemaHelper
        attr_reader :receivedAt, :validatedAt, :isValid

        def initialize(planning_application)
          @receivedAt = planning_application.received_at
          @validatedAt = planning_application.validated_at
          @isValid = planning_application.validated?

          if @isValid && @validatedAt.blank?
            # raise "Cannot convert: validatedAt is missing for a valid application"
          end
        end

        def as_json(*)
          {
            receivedAt: format_postsubmission_datetime(@receivedAt),
            validatedAt: format_postsubmission_datetime(@validatedAt),
            isValid: @isValid
          }
        end

        private
      end

      class Consultation
        include BopsApi::PostsubmissionApplicationSchemaHelper
        attr_reader :startDate, :endDate, :siteNotice, :pressNotice

        def initialize(planning_application)
          @startDate = planning_application.consultation.start_date
          @endDate = planning_application.consultation.end_date
          @siteNotice = planning_application.site_notices.last.present?
          @pressNotice = planning_application.press_notice.present?
        end

        def as_json(*)
          {
            startDate: format_postsubmission_date(@startDate),
            endDate: format_postsubmission_date(@endDate),
            siteNotice: @siteNotice,
            pressNotice: @pressNotice
          }
        end
      end

      class Assessment
        include BopsApi::PostsubmissionApplicationSchemaHelper
        attr_reader :expiryDate, :decisionNotice, :planningOfficerDecision, :planningOfficerDecisionDate,
                    :planningOfficerRecommendation, :committeeSentDate, :committeeDecision, :committeeDecisionDate
        attr_reader :priorApprovalRequired

        def initialize(planning_application)

          @expiryDate = planning_application.expiry_date
          @decisionNotice = get_decisionNotice(planning_application)

          # AssessmentDecisionSection
          @planningOfficerDecision = planning_application.decision
          @planningOfficerDecisionDate = planning_application.determined_at

          # AssessmentCommittee
          # TODO
          # @planningOfficerRecommendation = nil
          # @committeeSentDate = nil
          # @committeeDecision = planning_application.decision
          # @committeeDecisionDate = planning_application.determined_at

          # PriorApprovalAssessment
          @priorApprovalRequired = get_priorApprovalRequired(planning_application)
        end

        def as_json(*)
          data = {
            expiryDate: format_postsubmission_date(@expiryDate),
            decisionNotice: @decisionNotice
          }

          data[:planningOfficerDecision] = @planningOfficerDecision if @planningOfficerDecision
          data[:planningOfficerDecisionDate] = format_postsubmission_date(@planningOfficerDecisionDate) if @planningOfficerDecisionDate

          data[:priorApprovalRequired] = @priorApprovalRequired if @priorApprovalRequired          
          
          data
        end

        private

        def get_decisionNotice(planning_application)
          return unless planning_application.determined? 
          {
            url: "TODO"
          }
        end

        # Assumes this logic is setup for decisions for prior_approval
        # Prior Approval	Not required	Prior approval not required
        # Prior Approval	Granted	Prior approval required and approved
        # Prior Approval	Refused	Prior approval required and refused
        def get_priorApprovalRequired(planning_application)
          return unless planning_application.application_type.name == 'prior_approval' && planning_application.determined? 

          case planning_application.decision
          when 'granted', 'refused'
            true
          when 'not_required'
            false
          end
        end


      end

      class Appeal
        include BopsApi::PostsubmissionApplicationSchemaHelper
        attr_reader :reason, :lodgedDate, :validatedDate, :startedDate, :decisionDate, :decision, :files

        def initialize(planning_application)
            @reason = planning_application.appeal.reason
            @lodgedDate = planning_application.appeal.lodged_at&.utc
            @validatedDate = planning_application.appeal.validated_at&.utc
            @startedDate = planning_application.appeal.started_at&.utc
            @decisionDate = planning_application.appeal.determined_at&.utc
            @decision = planning_application.appeal.decision
            # @TODO converter
            @files = planning_application.appeal.documents
        end

        def as_json(*)
          {
            reason: @reason,
            lodgedDate: format_postsubmission_date(@lodgedDate),
            validatedDate: format_postsubmission_date(@validatedDate),
            startedDate: format_postsubmission_date(@startedDate),
            decisionDate: format_postsubmission_date(@decisionDate),
            decision: @decision,
            # files: @files
          }
        end
      end

      class LocalPlanningAuthority
        attr_reader :publicCommentsAcceptedUntilDecision
        def initialize(planning_application)
          @publicCommentsAcceptedUntilDecision = false
        end
        def as_json(*)
          {
            publicCommentsAcceptedUntilDecision: @publicCommentsAcceptedUntilDecision
          }
        end
      end

      class CaseOfficer
        attr_reader :name
        def initialize(planning_application)
          @name = planning_application.user&.name
          # raise "Cannot convert: case officer is missing" if @name.blank?
        end
        def as_json(*)
          {
            name: @name
          }
        end
      end

      class Metadata
        include BopsApi::PostsubmissionApplicationSchemaHelper
        attr_reader :organisation, :id, :schema, :generatedAt, :submittedAt

        def initialize(planning_application, submittedAt)
          @organisation = planning_application.params_v2&.dig(:metadata, :organisation) || "TODO" # TODO maxLength 4 The reference code for the organisation responsible for processing this planning application, sourced from planning.data.gov.uk/dataset/local-authority
          @id = planning_application.reference
          @schema = "https://raw.githubusercontent.com/theopensystemslab/digital-planning-data-schemas/refs/heads/main/schemas/postSubmissionApplication.json" 
          @generatedAt = Time.now
          @submittedAt = submittedAt
        end

        def as_json(*)
          {
            organisation: @organisation,
            id: @id,
            schema: @schema,
            generatedAt: format_postsubmission_datetime(@generatedAt),
            submittedAt: format_postsubmission_datetime(@submittedAt)
          }
        end
      end

      class OriginalSubmission
        attr_reader :submission

        def initialize(planning_application)
          # @submission = planning_application.params_v2
          @submission = {}
        end

        def as_json(*)
          @submission
        end

        private
      end

    end
  end
end