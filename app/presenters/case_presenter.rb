class CasePresenter

  def initialize(case_attributes)
    @case_attributes = case_attributes
    @patient_attributes = case_attributes[:patient] || {}
    @attachment_attributes = case_attributes[:attachments] || nil
  end

  def present
    {}.tap do |presented|
      presented[:id] = case_attributes["id"]
      presented[:anatomy] = case_attributes["anatomy"]
      presented[:side] = case_attributes["side"]
      presented[:patient] = PatientPresenter.new(patient_attributes).present
      presented[:attachments] = presented_attachments if attachment_attributes
    end
  end


  private

  attr_reader :case_attributes, :patient_attributes, :attachment_attributes

  def presented_attachments
    attachment_attributes.map{ |attrs| AttachmentPresenter.new(attrs).present }
  end

end