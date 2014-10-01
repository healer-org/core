class Patient < HealerRecord
  include SoftDelete

  validates_presence_of :name

  class << self
    def search(query)
      return [] unless query
      # TODO this should probably delegate to something like Sphinx
      active.where("lower(name) like ?", "%#{query.to_s.downcase}%")
    end
  end

  private

  def delete_associations!
    Case.where(patient_id: self.id).map(&:delete!)
  end
end
