class AppointmentsController < ApplicationController

  def index
    appointments = Appointment.includes(:patient).where(filter_params)
    presented = appointments.map { |r| presented(r) }

    render(
      json: Response.new(:data => presented, :root => "appointments"),
      status: :ok
    )
  end


  private

  def presented(appointment)
    attributes = appointment.attributes
    attributes[:patient] = appointment.patient.attributes
    AppointmentPresenter.new(attributes).present
  end

  def filter_params
    params.slice(:trip_id, :location)
  end

end