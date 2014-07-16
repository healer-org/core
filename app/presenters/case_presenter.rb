class CasePresenter

  def initialize(case_attributes)
    @case_attributes = case_attributes
    @patient_attributes = case_attributes[:patient] || {}
  end

  def present
    {}.tap do |presented|
      presented[:id] = case_attributes["id"]
      presented[:anatomy] = case_attributes["anatomy"]
      presented[:side] = case_attributes["side"]
      presented[:patient] = PatientPresenter.new(patient_attributes).present
    end
  end


  private

  attr_reader :case_attributes, :patient_attributes

end