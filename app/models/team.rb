# frozen_string_literal: true

class Team < Base
  has_and_belongs_to_many :missions
  has_and_belongs_to_many :providers
end
