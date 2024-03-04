# frozen_string_literal: true

class AssessmentDetail < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user
  has_one :comment, as: :commentable, dependent: :destroy

  enum(
    assessment_status: {
      not_started: "not_started",
      in_progress: "in_progress",
      complete: "complete"
    },
    _default: "not_started",
    _prefix: "assessment"
  )

  enum(
    review_status: {
      in_progress: "in_progress",
      complete: "complete"
    },
    _prefix: "review"
  )

  enum reviewer_verdict: {
    accepted: "accepted",
    edited_and_accepted: "edited_and_accepted",
    rejected: "rejected"
  }

  enum category: {
    summary_of_work: "summary_of_work",
    additional_evidence: "additional_evidence",
    site_description: "site_description",
    past_applications: "past_applications",
    consultation_summary: "consultation_summary",
    neighbour_summary: "neighbour_summary",
    amenity: "amenity",
    check_publicity: "check_publicity"
  }

  before_validation :set_user

  validates :assessment_status, presence: true
  validates :entry, presence: true, if: :validate_entry_presence?
  validate :tagged_entry, if: :neighbour_summary?

  validates(
    :additional_information,
    presence: true,
    if: :validate_additional_information_presence?
  )

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  delegate :consultees, to: :planning_application

  categories.each do |category|
    scope :"#{category}", -> { where(category:) }
  end

  def existing_or_new_comment
    comment || build_comment
  end

  def update_required?
    review_complete? && rejected?
  end

  def review_required?
    assessment_complete? && reviewer_verdict.blank?
  end

  private

  def validate_additional_information_presence?
    past_applications? && assessment_complete?
  end

  def validate_entry_presence?
    return false if accepted? || rejected?

    summary_of_work? ||
      site_description? || amenity? || neighbour_summary? ||
      (assessment_complete? && consultation_summary?)
  end

  def set_user
    self.user = user || Current.user
  end

  def tagged_entry
    return unless assessment_status == "complete"

    tag_array = NeighbourResponse::TAGS.dup

    entries = tag_array.push(:untagged).map { |tag| entry[/(?<=#{tag.to_s.humanize}:)\s\n/] }

    errors.add(:entry, "Fill in all summaries of comments") if entries.any?
  end
end
