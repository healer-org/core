# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(
  File.expand_path(
    File.join(
      File.dirname(__FILE__),
      ".ruby-version"
    )
  )
).split("-").last.chomp

gem "dotenv-rails"
gem "json-schema"
gem "rails", "~> 5.2"

gem "paperclip", "~> 5.2.0"

gem "pg"

group :development, :test do
  gem "byebug"
  gem "database_cleaner", "~> 1.6.0"
  gem "faker"
  gem "rspec-rails", "~> 3.7.0"
  gem "rubocop"
  gem "spring"
end
