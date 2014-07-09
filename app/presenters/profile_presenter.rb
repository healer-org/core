class ProfilePresenter

  def initialize(profile_attributes)
    @profile_attributes = profile_attributes
  end

  def present
    {}.tap do |presented|
      presented[:id] = profile_attributes["id"]
      presented[:name] = profile_attributes["name"]
      presented[:birth] = profile_attributes["birth"]
    end
  end


  private

  attr_reader :profile_attributes

end