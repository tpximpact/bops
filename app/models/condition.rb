# frozen_string_literal: true

class Condition < ApplicationRecord
  belongs_to :condition_set
  acts_as_list scope: :condition_set

  has_many :validation_requests, as: :owner, class_name: "ValidationRequest", dependent: :destroy

  validates :text, :reason, presence: true
  validates :title, presence: true, if: :pre_commencement?
  validate :ensure_planning_application_not_closed_or_cancelled, on: :update

  after_create :create_validation_request!, if: :pre_commencement?
  before_update :create_validation_request!, if: -> { pre_commencement? && should_create_validation_request? }

  delegate :planning_application, to: :condition_set

  scope :sorted, -> { sort_by(&:sort_key) }
  scope :not_cancelled, -> { where(cancelled_at: nil) }

  def checked?
    persisted? || errors.present?
  end

  def sort_key
    [title_key, timestamp_key, Float::INFINITY].compact.first
  end

  def review_title
    title.presence || "Other"
  end

  def current_validation_request
    validation_requests.order(:created_at).last
  end

  class << self
    def standard_conditions
      I18n.t(:conditions_list).map { |k, v| Condition.new(v) }
    end
  end

  private

  def titles
    @titles ||= I18n.t(:conditions_list).values.pluck(:title)
  end

  def title_key
    titles.index(title)
  end

  def timestamp_key
    created_at&.to_i
  end

  def should_create_validation_request?
    return unless current_validation_request.closed?
    title_changed? || text_changed? || reason_changed?
  end

  def create_validation_request!
    validation_requests.create!(type: "PreCommencementConditionValidationRequest", planning_application: condition_set.planning_application, post_validation: true, user: Current.user)
  end

  def pre_commencement?
    condition_set.pre_commencement?
  end

  def ensure_planning_application_not_closed_or_cancelled
    errors.add(:base, "Cannot modify conditions when planning application has been closed or cancelled") if planning_application.closed_or_cancelled?
  end
end
