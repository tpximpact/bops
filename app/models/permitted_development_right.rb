# frozen_string_literal: true

class PermittedDevelopmentRight < ApplicationRecord
  class NotCreatableError < StandardError; end

  belongs_to :planning_application

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  with_options presence: true do
    validates :status, :review_status
    validates :removed_reason, if: :removed
  end

  enum :status, %i[
    in_progress
    checked
    removed
    to_be_reviewed
  ].index_with(&:to_s)

  enum :review_status, %i[
    review_not_started
    review_in_progress
    review_complete
  ].index_with(&:to_s)

  validate :reviewer_is_present?
  validate :planning_application_can_review_assessment

  before_create :ensure_no_open_permitted_development_right_response!
  before_update :set_status_to_be_reviewed, if: :reviewer_comment?
  before_update :set_reviewer_edited, if: :removed_reason_changed?

  scope :with_reviewer_comment, -> { where.not(reviewer_comment: nil) }
  scope :not_review_in_progress, -> { where.not(review_status: "review_in_progress") }
  scope :returned, -> { with_reviewer_comment.not_review_in_progress.where(accepted: false) }

  def update_required?
    review_complete? && !accepted
  end

  def review_started?
    review_in_progress? || review_complete?
  end

  private

  def set_status_to_be_reviewed
    return if to_be_reviewed?
    return if review_in_progress?
    return if accepted

    update!(status: "to_be_reviewed")
  end

  def set_reviewer_edited
    return if reviewer_edited
    return unless reviewer && accepted

    update!(reviewer_edited: true)
  end

  def reviewer_is_present?
    return unless reviewer_comment?
    return if reviewer

    errors.add(:base, "Reviewer must be present when returning to officer with a comment")
  end

  def planning_application_can_review_assessment
    return unless planning_application.last_recommendation_accepted?

    errors.add(
      :base,
      I18n.t("permitted_development_rights.review_assessment_error")
    )
  end

  def ensure_no_open_permitted_development_right_response!
    last_permitted_development_right = PermittedDevelopmentRight.where(planning_application:).last
    return unless last_permitted_development_right
    return if last_permitted_development_right.to_be_reviewed?

    raise NotCreatableError,
      "Cannot create a permitted development right response when there is already an open response"
  end
end
