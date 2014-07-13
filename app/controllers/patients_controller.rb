class PatientsController < ApplicationController

  def index
    patients = Patient.all
    presented_patients = patients.map { |patient| presented(patient) }

    render(
      json: Response.new(:data => presented_patients, :root => "patients"),
      status: :ok
    )
  end

  def show
    patient = Patient.find(params[:id])

    render_one(patient)
  end

  def create
    patient = Patient.create!(patient_params)

    render_one(patient, :created)
  end

  def update
    patient = Patient.find(params[:id])
    patient.update_attributes!(patient_params)

    render_one(patient)
  end


  private

  def presented(patient)
    PatientPresenter.new(patient.attributes).present
  end

  def patient_params
    # require 'pry'; binding.pry
    params.require(:patient).permit(:name, :birth, :death, :gender)
  end

  def render_one(patient, status = :ok)
    render(
      json: Response.new(:data => presented(patient), :root => "patient"),
      status: status
    )
  end

end