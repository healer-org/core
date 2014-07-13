class PatientPresenter

  def initialize(patient_attributes)
    @patient_attributes = patient_attributes
  end

  def present
    {}.tap do |presented|
      presented[:id] = patient_attributes["id"]
      presented[:name] = patient_attributes["name"]
      presented[:gender] = patient_attributes["gender"]
      presented[:birth] = patient_attributes["birth"]
      presented[:death] = patient_attributes["death"]
    end
  end


  private

  attr_reader :patient_attributes

end