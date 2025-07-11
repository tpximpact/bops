# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class BaseParser
      attr_reader :params, :local_authority

      def initialize(params, local_authority:)
        @params = params&.with_indifferent_access
        @local_authority = local_authority
      end
    end
  end
end
