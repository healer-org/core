class Provider < Base
  has_and_belongs_to_many :teams
  has_and_belongs_to_many :procedures
end
