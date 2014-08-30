class Patient < HealerRecord
  include SoftDelete

  validates_presence_of :name

  class << self
    def default_scope
      where.not(status: "deleted")
    end

    def search(query)
      # TODO this should probably delegate to something like Sphinx
      all.where("lower(name) like ?", "%#{query.to_s.downcase}%")
    end
  end

  private

  def delete_associations!
    Case.where(patient_id: self.id).map(&:delete!)
  end
end
