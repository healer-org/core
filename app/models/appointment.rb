class Appointment < HealerRecord
  belongs_to :patient
  validates :patient, presence: true
end
