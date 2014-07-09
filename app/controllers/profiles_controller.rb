class ProfilesController < ApplicationController

  def index
    profiles = Profile.all
    presented_profiles = profiles.map do |p|
      ProfilePresenter.new(p.attributes).present
    end

    render(
      json: Response.new(:data => presented_profiles, :root => "profiles"),
      status: :ok
    )
  end

  def show
    profile = Profile.find(params[:id])
    render_one(profile)
  end

  def create
    profile = Profile.create!(profile_params)
    render_one(profile, :created)
  end

  def update
    profile = Profile.find(params[:id])
    profile.update_attributes!(profile_params)
    render_one(profile)
  end


  private

  def profile_params
    params.require(:profile).permit(:name, :birth)
  end

  def render_one(profile, status = :ok)
    render(
      json: Response.new(
        :data => ProfilePresenter.new(profile.attributes).present,
        :root => "profile"
      ),
      status: status
    )
  end

end
