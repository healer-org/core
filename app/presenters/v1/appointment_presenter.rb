class V1::AppointmentPresenter < V1::BasePresenter

  def initialize(attributes)
    @attributes = attributes
    @patient_attributes = attributes[:patient] || {}
  end

  def present
    {}.tap do |presented|
      presented[:id] = attributes["id"]
      presented[:start] = attributes["start"]
      presented[:order] = attributes["order"]
      presented[:end] = attributes["end"]
      presented[:location] = attributes["location"]
      presented[:patient] = V1::PatientPresenter.new(patient_attributes).present
    end
  end


  private

  attr_reader :attributes, :patient_attributes

end