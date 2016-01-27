class Appointment < Base
  belongs_to :patient
  validates :patient, presence: true
end
