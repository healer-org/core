class AppointmentPresenter

  def initialize(attributes)
    @attributes = attributes
    @patient_attributes = attributes[:patient] || {}
  end

  def present
    {}.tap do |presented|
      presented[:id] = attributes["id"]
      presented[:start_date] = attributes["start_date"]
      presented[:start_time] = attributes["start_time"]
      presented[:start_ordinal] = attributes["start_ordinal"]
      presented[:end_date] = attributes["end_date"]
      presented[:end_time] = attributes["end_time"]
      presented[:location] = attributes["location"]
      presented[:patient] = PatientPresenter.new(patient_attributes).present
    end
  end


  private

  attr_reader :attributes, :patient_attributes

end