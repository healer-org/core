FactoryGirl.define do
  factory :active_case, class: Case do
    patient
    anatomy { %w(hip knee foot ankle)[rand(4)] }
    side { %w(right left)[rand(3)] }
    status "active"
  end

  factory :deleted_case, class: Case, parent: :active_case do
    status "deleted"
  end
end

