class AppointmentPresenter

  def initialize(attributes)
    @attributes = attributes
    @patient_attributes = attributes[:patient] || {}
  end

  def present
    {}.tap do |presented|
      presented[:id] = attributes["id"]
      presented[:startTime] = attributes["start_time"]
      presented[:startOrdinal] = attributes["start_ordinal"]
      presented[:endTime] = attributes["end_time"]
      presented[:location] = attributes["location"]
      presented[:patient] = PatientPresenter.new(patient_attributes).present
    end
  end


  private

  attr_reader :attributes, :patient_attributes

end