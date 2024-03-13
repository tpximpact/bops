# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  NAME_ORDER = %w[prior_approval planning_permission lawfulness_certificate].freeze

  default_scope { in_order_of(:name, NAME_ORDER).order(:name) }

  enum :status, {inactive: "inactive", active: "active", retired: "retired"}

  has_many :planning_applications, dependent: :restrict_with_exception

  validates :name, presence: true

  attribute :features, ApplicationTypeFeature.to_type

  with_options to: :features do
    delegate :planning_conditions?
    delegate :permitted_development_rights?
    delegate :site_visits?
  end

  def full_name
    name.humanize
  end

  def human_name
    I18n.t("application_types.#{name}")
  end

  def legislation_link
    fetch_legislation_translation("link")
  end

  def legislation_link_text
    fetch_legislation_translation("link_text")
  end

  def legislation_description
    fetch_legislation_translation("description")
  end

  def consultation?
    steps.include?("consultation")
  end

  def assessor_remarks
    assessment_details.excluding("past_applications", "check_publicity")
  end

  def irrelevant_tags(key)
    case key
    when "plans"
      Document::PLAN_TAGS - document_tags[key]
    when "evidence"
      Document::EVIDENCE_TAGS - document_tags[key]
    when "supporting_documents"
      (Document::SUPPORTING_DOCUMENT_TAGS - ["disabilityExemptionEvidence"]) - document_tags[key]
    when "other"
      []
    else
      raise ArgumentError, "Unexpected document tag type: #{key}"
    end
  end

  class << self
    def menu(scope = all)
      scope.order(name: :asc).select(:name, :id).map do |application_type|
        [application_type.full_name, application_type.id]
      end
    end
  end

  private

  def part_and_section
    "#{part}#{section}"
  end

  def fetch_legislation_translation(key)
    I18n.t("application_types.legislation.#{name}.#{part_and_section}.#{key}", default: false)
  end
end
