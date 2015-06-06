class V1::AppointmentsController < V1::BaseController

  def index
    appointments = Appointment.includes(:patient).where(filter_params).
      where.not(patients: { status: "deleted" })

    presented = appointments.map { |r| presented(r) }

    render(
      json: Response.new(:data => presented, :root => "appointments"),
      status: :ok
    )
  end

  def show
    record = Appointment.includes(:patient).
      where.not(patients: { status: "deleted" }).
      find_by!(id: params[:id])

    render_one(record)
  end

  def create
    validate_json_request!

    appointment_record = Appointment.new(appointment_params)
    raise ActionController::ParameterMissing.new("Missing patient id") unless appointment_record.patient_id

    patient_record = Patient.active.find(appointment_record.patient_id)

    appointment_record.save!
    render_one(appointment_record, :created)
  end

  def update
    validate_json_request!

    appointment_record = Appointment.includes(:patient).
      where.not(patients: { status: "deleted" }).find(params[:id])

    params = appointment_params
    raise Errors::MismatchedPatient if mismatched_patient?(appointment_record, params)

    appointment_record.update_attributes!(params)
    render_one(appointment_record)
  end

  def mismatched_patient?(appointment_record, params)
    params[:patient_id] && params[:patient_id] != appointment_record.patient_id
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
    %w(start end).each do |k|
      attributes[k] = attributes[k].to_s(:iso8601) if attributes[k]
    end
    attributes[:patient] = appointment.patient.attributes
    V1::AppointmentPresenter.new(attributes).present
  end

  def render_one(appointment_record, status = :ok)
    render(
      json: Response.new(:data => presented(appointment_record), :root => "appointment"),
      status: status
    )
  end

  def appointment_params
    filtered_params = params.require(:appointment).permit(
      :trip_id,
      :patient_id,
      :start,
      :order,
      :location,
      :end)

    [:start, :end].each do |param|
      filtered_params[param] = DateTime.parse(filtered_params[param]) if filtered_params[param]
    end
    filtered_params
  end

  def filter_params
    params.permit(:trip_id, :location).slice(:trip_id, :location)
  end

end