# frozen_string_literal: true

class DocumentComponent < ViewComponent::Base
  def initialize(planning_application:, document:)
    @planning_application = planning_application
    @document = document
  end

  private

  attr_reader :planning_application, :document

  delegate(
    :replacement_document_validation_request,
    to: :document
  )

  def link_text
    truncated_document_name
  end

  def truncated_document_name
    truncate(document_name.to_s, length: 50)
  end

  def document_name
    document.numbers.presence || document.name
  end

  def link_active?
    true
  end

  def link_path
    if status == :invalid
      planning_application_validation_replacement_document_validation_request_path(
        planning_application,
        replacement_document_validation_request
      )
    else
      edit_planning_application_document_path(
        planning_application,
        document,
        validate: :yes
      )
    end
  end

  def status
    @status ||= if document.validated?
      :valid
    elsif replacement_document_validation_request&.open_or_pending?
      :invalid
    elsif ReplacementDocumentValidationRequest.find_by(new_document: document).present?
      :updated
    else
      :not_started
    end
  end

  def status_tag_component
    StatusTags::BaseComponent.new(status:)
  end
end
