class Case < HealerRecord
  include SoftDelete

  belongs_to :patient
  has_many :attachments, as: :record
end
