class Procedure < HealerRecord
  belongs_to :appointment
  belongs_to :case

  store_accessor :data, :date

  validates :case, presence: true
  validates :date, presence: true
end