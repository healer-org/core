class ProfilePresenter

  def initialize(profile)
    @profile = profile
  end

  def present
    {}.tap do |presented|
      presented[:id] = profile["id"]
      presented[:name] = profile["name"]
      presented[:birth] = profile["birth"]
    end
  end


  private

  attr_reader :profile

end