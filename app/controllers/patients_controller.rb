class PatientsController < ApplicationController

  def index
    patients = Patient.all
    profiles = Profile.all.where(:id => patients.map(&:profile_id))
    # presented_profiles = profiles.map{ |p| ProfilePresenter.new(p).present }
    render(
      json: Response.new(
        :data => merge_patient_and_profile_attributes(patients, profiles),
        :root => "patients"
      ),
      status: :ok
    )
  end


  private

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