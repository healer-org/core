class Case < HealerRecord
  include SoftDelete

  belongs_to :patient
end
