FactoryGirl.define do
  factory :appointment do
    patient
    trip_id 1
    start_time Time.utc(2007,8,7,8,30,00)
    start_ordinal 3
    location "room 4"
    end_time Time.utc(2007,8,7,9,00,00)
  end

  factory :future_appointment, class: Appointment, parent: :appointment do
    start_time Time.parse((Time.now + 1.week).to_s)
  end

  factory :past_appointment, class: Appointment, parent: :appointment do
    start_time Time.now - 1.week
  end
end
