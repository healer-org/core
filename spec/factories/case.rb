FactoryGirl.define do
  factory :case do
    patient
    anatomy { %w(hip knee foot ankle)[rand(4)] }
    side { %w(right left)[rand(3)] }
  end
end

