class Patient < ActiveRecord::Base
  validates_presence_of :profile_id

  def to_json(options = {})
    Rails.logger.warn("* using ActiveRecord to_json *")
    super
  end
end
