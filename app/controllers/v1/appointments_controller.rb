# frozen_string_literal: true

module V1
  class AppointmentsController < BaseController
    def index
      appointments = base_appointment_scope.where(filter_params)

      presented = appointments.map { |r| presented(r) }

      render(
        json: Response.new(data: presented, root: "appointments"),
        status: :ok
      )
    end

    def show
      record = base_appointment_scope.find_by!(id: params[:id])

      render_one(record)
    end

    def create
      appointment_record = Appointment.new(appointment_params)
      unless appointment_record.patient_id
        raise ActionController::ParameterMissing, "Missing patient id"
      end

      Patient.active.find(appointment_record.patient_id)

      appointment_record.save!
      render_one(appointment_record, :created)
    end

    def update
      appointment_record = base_appointment_scope.find(params[:id])

      params = appointment_params
      raise Errors::MismatchedPatient if mismatched_patient?(appointment_record, params)

      appointment_record.update_attributes!(params)
      render_one(appointment_record)
    end

    def mismatched_patient?(appointment_record, params)
      params[:patient_id] && params[:patient_id].to_i != appointment_record.patient_id
    end

    def destroy
      persisted_record = Appointment.find(params[:id])
      persisted_record.destroy

      render(
        json: Response.new(data: { message: "Deleted" }),
        status: :ok
      )
    end

    private

    def base_appointment_scope
      Appointment.includes(:patient).where.not(patients: { status: "deleted" })
    end

    def presented(appointment)
      attributes = appointment.attributes
      %w[start end].each do |k|
        attributes[k] = attributes[k].to_s(:iso8601) if attributes[k]
      end
      attributes[:patient] = appointment.patient.attributes
      AppointmentPresenter.new(attributes).present
    end

    def render_one(appointment_record, status = :ok)
      render(
        json: Response.new(data: presented(appointment_record), root: "appointment"),
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
        :end
      )

      %i[start end].each do |param|
        filtered_params[param] = DateTime.parse(filtered_params[param]) if filtered_params[param]
      end
      filtered_params
    end

    def filter_params
      params.permit(:trip_id, :location).slice(:trip_id, :location)
    end
  end
end
