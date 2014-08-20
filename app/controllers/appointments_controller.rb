class AppointmentsController < ApplicationController

  def index
    appointments = Appointment.includes(:patient).where(filter_params)
    presented = appointments.map { |r| presented(r) }

    render(
      json: Response.new(:data => presented, :root => "appointments"),
      status: :ok
    )
  end

  def create
    appointment_record = Appointment.new(appointment_params)
    raise ActionController::ParameterMissing.new("Missing patient id") unless appointment_record.patient_id

    patient_record = Patient.find(appointment_record.patient_id)

    appointment_record.save!
    render_one(appointment_record, :created)
  end

  def delete
    persisted_record = Appointment.find(params[:id])
    persisted_record.destroy

    render(
      json: Response.new(:data => { message: "Deleted" }),
      status: :ok
    )
  end


  private

  def presented(appointment)
    attributes = appointment.attributes
    %w(start_time end_time).each do |k|
      attributes[k] = attributes[k].to_s(:iso8601) if attributes[k]
    end
    attributes[:patient] = appointment.patient.attributes
    AppointmentPresenter.new(attributes).present
  end

  def render_one(appointment_record, status = :ok)
    render(
      json: Response.new(:data => presented(appointment_record), :root => "appointment"),
      status: status
    )
  end

  def appointment_params
    filtered_params = params.require(:appointment).permit(
      :patient_id,
      :start_time,
      :start_ordinal,
      :location,
      :end_time)

    [:start_time, :end_time].each do |param|
      filtered_params[param] = DateTime.parse(filtered_params[param]) if filtered_params[param]
    end
    filtered_params
  end

  def filter_params
    params.slice(:trip_id, :location)
  end

end