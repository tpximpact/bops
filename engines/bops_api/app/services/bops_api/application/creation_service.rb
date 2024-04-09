# frozen_string_literal: true

module BopsApi
  module Application
    class CreationService
      def initialize(local_authority: nil, user: nil, params: nil, planning_application: nil, send_email: false)
        if planning_application
          initialize_from_planning_application(planning_application)
        else
          @local_authority = local_authority
          @user = user
          @params = params
          @send_email = send_email
        end
      end

      def call!
        save!(build_planning_application)
      end

      private

      attr_reader :local_authority, :params, :user

      def data_params
        @data_params ||= params.fetch(:data)
      end

      def files
        @files ||= params.fetch(:files)
      end

      def build_planning_application
        PlanningApplication.new(planning_application_params).tap do |pa|
          pa.api_user_id = user.id
          pa.local_authority_id = local_authority.id
        end
      end

      def planning_application_params
        {}.tap do |pa_params|
          pa_params.merge!(parsed_data)
          pa_params.merge!(other_params)
          pa_params.merge!(planx_planning_data_attributes: Parsers::SubmissionParser.new(params).parse)
        end
      end

      def parsed_data
        parsers.each_with_object({}) do |(parser, data), hash|
          hash.merge!(parser.new(data).parse)
        end
      end

      def parsers
        {
          "ApplicantParser" => data_params[:applicant],
          "AgentParser" => data_params[:applicant][:agent],
          "FeeParser" => data_params[:application][:fee],
          "AddressParser" => data_params[:property][:address],
          "ApplicationTypeParser" => data_params[:application][:type],
          "PreAssessmentParser" => params[:preAssessment],
          "ProposalParser" => data_params[:proposal],
          "ProposalDetailsParser" => params[:responses]
        }.transform_keys { |key| Parsers.const_get(key) }
      end

      def other_params
        {
          user_role: data_params[:user_role],
          from_production: params[:from_production].present?
        }
      end

      def save!(planning_application)
        PlanningApplication.transaction do
          if planning_application.save!
            PlanningApplicationDependencyJob.perform_later(planning_application:, user:, files:, params:, send_email: @send_email)
          end
        end

        CreateNeighbourBoundaryGeojsonJob.perform_later(planning_application) if planning_application.consultation
        MarkAcceptedJob.set(wait: 5.minutes).perform_later(planning_application)

        planning_application
      end

      def initialize_from_planning_application(planning_application)
        params_v2 = planning_application.params_v2 || raise_not_permitted_to_clone_error

        @params = params_v2.with_indifferent_access
        @local_authority = planning_application.local_authority
        @user = planning_application.api_user
        @send_email = false
      end

      def raise_not_permitted_in_production_error
        raise BopsApi::Errors::NotPermittedError, "Creating planning applications using this endpoint is not permitted in production"
      end

      def raise_not_permitted_to_clone_error
        raise BopsApi::Errors::NotPermittedError, "Planning application cannot be cloned without V2 params"
      end
    end
  end
end
