class Appointment < HealerRecord
  belongs_to :patient
  validates_presence_of :patient
end
