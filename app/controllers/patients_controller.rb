class PatientsController < ApplicationController

  def index
    patients = Patient.where(status: "active")
    if params[:showCases]
      cases_records = Case.where(:patient_id => patients.map(&:id))
    end

    # TODO there's probably a nice simple way to do this via AR, but avoiding
    # that dependency for now. decide whether to depend on AR or refactor as is.
    presented_patients = patients.map do |patient|
      patient_attributes = patient.attributes
      if cases_records
        patient_attributes[:cases] = cases_records.select do |c|
          c.patient_id == patient.id
        end.map(&:attributes)
      end

      present(patient_attributes)
    end

    render(
      json: Response.new(:data => presented_patients, :root => "patients"),
      status: :ok
    )
  end

  def show
    patient = Patient.find_by!(id: params[:id], status: "active")
    patient_attributes = patient.attributes

    # TODO there's probably a nice simple way to do this via AR, but avoiding
    # that dependency for now. decide whether to depend on AR or refactor as is.
    if params[:showCases]
      case_records = Case.where(:patient_id => patient.id)
      patient_attributes[:cases] = case_records.map(&:attributes)
    end

    render_one(patient_attributes)
  end

  def create
    patient = Patient.create!(patient_params)

    render_one(patient.attributes, :created)
  end

  def update
    patient = Patient.find(params[:id])
    patient.update_attributes!(patient_params)

    render_one(patient.attributes)
  end

  def delete
    patient = Patient.find(params[:id])
    patient.delete!

    render(
      json: Response.new(:data => { message: "Deleted" }),
      status: :ok
    )
  end


  private

  def present(patient_attributes)
    PatientPresenter.new(patient_attributes).present
  end

  def patient_params
    params.require(:patient).permit(:name, :birth, :death, :gender)
  end

  def render_one(attributes, status = :ok)
    render(
      json: Response.new(:data => present(attributes), :root => "patient"),
      status: status
    )
  end

end