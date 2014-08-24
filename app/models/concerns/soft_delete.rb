module SoftDelete
  ACTIVE_STATUSES = %w(active).freeze

  extend ActiveSupport::Concern

  included do
    default_scope { where.not(status: "deleted") }
  end

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def delete!
    transaction do
      update_attributes!(status: "deleted")
      delete_associations!
      log_delete
    end
  end

  def log_delete
    Rails.logger.info("id=#{self.id} object=#{self.class.name} action=delete")
  end

  def delete_associations!; end
end