# frozen_string_literal: true

class Appointment < Base
  belongs_to :patient
  validates :patient, presence: true
end
