class Patient < HealerRecord
  include SoftDelete

  def self.default_scope
    where.not(status: "deleted")
  end

  validates_presence_of :name


  private

  def delete_associations!
    Case.where(patient_id: self.id).map(&:delete!)
  end
end
