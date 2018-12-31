# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../config/environment', __dir__)
require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.include CustomMatchers
  config.include HTTP::JsonHelpers
  config.include HTTP::HeaderHelpers
  config.include HTTP::ResponseHelpers
end
