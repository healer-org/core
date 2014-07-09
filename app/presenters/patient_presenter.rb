class PatientPresenter

  def initialize(patient_attributes, profile_attributes)
    @patient_attributes = patient_attributes
    @profile_attributes = profile_attributes
  end

  def present
    {}.tap do |presented|
      presented[:id] = profile_attributes["id"]
      presented[:name] = profile_attributes["name"]
      presented[:gender] = patient_attributes["gender"]
      presented[:birth] = profile_attributes["birth"]
      presented[:death] = patient_attributes["death"]
    end
  end


  private

  attr_reader :patient_attributes, :profile_attributes

end