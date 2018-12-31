# frozen_string_literal: true

class Team < Base
  has_and_belongs_to_many :missions
end
