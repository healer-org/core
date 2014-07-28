require "faker"

FactoryGirl.define do
  factory :patient do
    name { Faker::Name.name }
    birth { Date.today-rand(365 * 70) }
    gender { %w(M F)[rand(3)] }
    status "active"
  end

  factory :deleted_patient, class: Patient, parent: :patient do
    status "deleted"
  end

  factory :deceased_patient, class: Patient, parent: :patient do
    death { Date.today - rand(3).years }
  end
end