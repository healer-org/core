class Patient < ActiveRecord::Base
  validates_presence_of :name

  def to_json(options = {})
    Rails.logger.warn("* using ActiveRecord to_json *")
    super
  end

  def delete!
    # TODO fire event
    Rails.logger.info("action=delete patient_id=#{self.id}")
    update_attributes!(status: "deleted")
  end

  def active?
    status == "active"
  end
end
