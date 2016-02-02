require File.expand_path('../boot', __FILE__)

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Healer
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    Dir[Rails.root.join("app/middleware/**/*.rb")].each { |f| require f }

    config.autoload_paths += %W(
      #{config.root}/app/**/
      #{config.root}/lib
    )
    config.active_record.raise_in_transactional_callbacks = true
  end
end
