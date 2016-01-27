class Case < Base
  include SoftDelete

  belongs_to :patient
  has_many :attachments, as: :record
  has_many :procedures
end
