class Profile < ActiveRecord::Base
  validates_presence_of :name

  def to_json(options = {})
    Rails.logger.warn("* using ActiveRecord to_json *")
    super
  end
end
