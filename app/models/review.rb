# frozen_string_literal: true

class Review < ApplicationRecord
  class NotCreatableError < StandardError; end
  store_accessor :specific_attributes, %w[decision decision_reason summary decision_type removed review_type]

  belongs_to :owner, polymorphic: true

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  with_options presence: true do
    validates :action, if: :review_complete?
    validates :comment, if: :rejected?
    validates :status, :review_status
    validates :decision, :decision_reason, if: -> { owner_is_immunity_detail? && enforcement? }
    validates :summary, if: -> { owner_is_immunity_detail? && decision_is_immune? }
  end

  validate :all_policies_are_determined, if: :owner_is_planning_application_policy_class?

  before_create :ensure_no_open_evidence_review_immunity_detail_response!, if: :owner_is_immunity_detail?
  before_create :ensure_no_open_enforcement_review_immunity_detail_response!, if: :owner_is_immunity_detail?
  before_commit :ensure_consultation_has_finished!, if: :owner_is_consultation?
  before_update :set_status_to_be_complete, if: :accepted?
  before_update :set_status_to_be_reviewed, if: :comment?
  before_update :set_reviewed_at, if: :reviewer_present?

  enum :action, %i[
    accepted
    edited_and_accepted
    rejected
  ].index_with(&:to_s)

  enum :status, %i[
    not_started
    in_progress
    to_be_reviewed
    complete
    updated
  ].index_with(&:to_s), default: "not_started"

  enum :review_status, %i[
    review_complete
    review_in_progress
    review_not_started
  ].index_with(&:to_s)

  scope :review_type, ->(type) { create_with(review_type: type).where("specific_attributes->>'review_type' = ?", type) }
  scope :evidence, -> { review_type("evidence") }
  scope :enforcement, -> { review_type("enforcement") }
  scope :neighbour_reviews, -> { review_type("neighbour") }
  scope :not_accepted, -> { where(action: "rejected").order(created_at: :asc) }
  scope :reviewer_not_accepted, -> { not_accepted.where.not(reviewed_at: nil) }
  scope :consultees_checked, -> { review_type("consultees_checked") }
  scope :reviewed, -> { where.not(reviewer_id: nil) }
  scope :with_reviewer, -> { includes(:reviewer) }

  def complete_or_to_be_reviewed?
    review_complete? || to_be_reviewed?
  end

  def decision_is_immune?
    return if specific_attributes.nil?

    specific_attributes["decision"] == "Yes"
  end

  def decision_is_not_immune?
    return if specific_attributes.nil?

    specific_attributes["decision"] == "No"
  end

  def started?
    status != "not_started"
  end

  def user
    reviewer
  end

  def text
    comment
  end

  private

  def set_reviewed_at
    Time.zone.now
  end

  def reviewer_present?
    return if reviewer.nil?

    action_was.nil?
  end

  def set_status_to_be_complete
    self.comment = nil
    self.status = "complete"
  end

  def set_status_to_be_reviewed
    return if to_be_reviewed?
    return if in_progress?
    return if accepted?
    return if updated?

    update!(status: "to_be_reviewed")
  end

  def set_reviewer_edited
    return if reviewer_edited
    return unless reviewer
    return if rejected?

    update!(reviewer_edited: true)
  end

  def owner_is_immunity_detail?
    owner_type == "ImmunityDetail"
  end

  def owner_is_consultation?
    owner_type == "Consultation"
  end

  def owner_is_planning_application_policy_class?
    owner_type == "PlanningApplicationPolicyClass"
  end

  def enforcement?
    return if specific_attributes.nil?

    specific_attributes["review_type"] == "enforcement"
  end

  def evidence?
    return if specific_attributes.nil?

    specific_attributes["review_type"] == "evidence"
  end

  def ensure_no_open_evidence_review_immunity_detail_response!
    return if enforcement?

    last_evidence_review_immunity_detail = owner.current_evidence_review_immunity_detail
    return unless last_evidence_review_immunity_detail
    return if last_evidence_review_immunity_detail.reviewed_at?

    raise NotCreatableError,
      "Cannot create an evidence review immunity detail response when there is already an open response"
  end

  def ensure_no_open_enforcement_review_immunity_detail_response!
    return if evidence?

    last_enforcement_review_immunity_detail = owner.current_enforcement_review_immunity_detail
    return unless last_enforcement_review_immunity_detail
    return if last_enforcement_review_immunity_detail.reviewed_at?

    raise NotCreatableError,
      "Cannot create an enforcement review immunity detail response when there is already an open response"
  end

  def ensure_consultation_has_finished!
    return unless owner.planning_application.awaiting_determination?
    return if owner.end_date.nil? || owner.end_date <= Time.zone.now
    return unless review_complete? && complete?

    raise NotCreatableError,
      "Consultation expiry date must be in the past. You cannot mark this as complete until the consultation period is complete."
  end

  def all_policies_are_determined
    return unless status == "complete"
    policies = owner.policy_class.planning_application_policy_sections.where(planning_application_id: owner.planning_application)
    return if policies.none?(&:to_be_determined?)

    errors.add(:base, :policies_to_be_determined)
  end
end
