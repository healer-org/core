# frozen_string_literal: true

class Patient < Base
  include SoftDelete

  validates :name, presence: true

  class << self
    def search(query)
      return [] unless query

      active.where("lower(name) like ?", "%#{query.to_s.downcase}%")
    end
  end

  private

  def delete_associations!
    Case.where(patient_id: id).map(&:delete!)
  end
end
