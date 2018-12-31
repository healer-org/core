# frozen_string_literal: true

class Base < ActiveRecord::Base
  self.abstract_class = true

  def to_json(options = {})
    Rails.logger.warn("* using ActiveRecord to_json *")
    super
  end
end
