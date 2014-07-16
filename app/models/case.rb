class Case < ActiveRecord::Base
  belongs_to :patient
  accepts_nested_attributes_for :patient
end
