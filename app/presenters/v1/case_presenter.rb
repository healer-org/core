class V1::CasePresenter < V1::BasePresenter

  def initialize(case_attributes)
    @case_attributes = case_attributes
    @patient_attributes = case_attributes[:patient] || {}
    @attachment_attributes = case_attributes[:attachments] || nil
    @procedure_attributes = case_attributes[:procedures] || nil
  end

  def present
    {}.tap do |presented|
      presented[:id] = case_attributes["id"]
      presented[:anatomy] = case_attributes["anatomy"]
      presented[:side] = case_attributes["side"]
      presented[:patient] = V1::PatientPresenter.new(patient_attributes).present
      presented[:attachments] = presented_attachments if attachment_attributes
      presented[:procedures] = presented_procedures if procedure_attributes
    end
  end


  private

  attr_reader :case_attributes
  attr_reader :patient_attributes
  attr_reader :attachment_attributes
  attr_reader :procedure_attributes

  def presented_attachments
    attachment_attributes.map{ |attrs| V1::AttachmentPresenter.new(attrs).present }
  end

  def presented_procedures
    procedure_attributes.map{ |attrs| attrs }
  end

end