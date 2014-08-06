FactoryGirl.define do
  factory :appointment do
    patient
    trip_id 1
  end

  factory :upcoming_appointment, class: Appointment, parent: :appointment do
    start_date Time.now + 1.week
  end

  factory :past_appointment, class: Appointment, parent: :appointment do
    start_date Time.now - 1.week
  end
end
