class Case < ActiveRecord::Base
  belongs_to :patient

  def self.default_scope
    where.not(status: "deleted")
  end

  def delete!
    # TODO fire event
    Rails.logger.info("id=#{self.id} object=#{self.class.name} action=delete")
    update_attributes!(status: "deleted")
  end

  def active?
    status == "active"
  end
end
