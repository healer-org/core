class PatientsController < ApplicationController

  def index
    patients = Patient.all
    profiles = Profile.all.where(:id => patients.map(&:profile_id))
    presented_patients = patients.map do |patient|
      profile = profiles.detect{ |p| p.id == patient.profile_id }
      PatientPresenter.new(patient.attributes, profile.attributes).present
    end

    render(
      json: Response.new(:data => presented_patients, :root => "patients"),
      status: :ok
    )
  end

  def show
    patient = Patient.find_by_profile_id(params[:id])
    profile = Profile.find_by_id(params[:id])

    raise ActiveRecord::RecordNotFound unless patient && profile
    render_one(patient, profile)
  end


  private

  def render_one(patient, profile, status = :ok)
    render(
      json: Response.new(
        :data =>  PatientPresenter.new(patient.attributes, profile.attributes).present,
        :root => "patient"
      ),
      status: status
    )
  end

  def merge_patient_and_profile_attributes(patients, profiles)
    patients.map do |patient|
      profile = profiles.detect{ |p| p.id == patient.profile_id }

      {
       id: profile.id,
       name: profile.name,
       birth: profile.birth,
       death: patient.death,
       gender: patient.gender
      }
    end
  end

end