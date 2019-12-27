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
gem "mimemagic"
gem "paperclip", "~> 5.2.0"
gem "pg"
gem "puma"
gem "rails", "~> 6"
gem "rake"

group :development, :test do
  gem "byebug"
  gem "database_cleaner", "~> 1.6.0"
  gem "faker"
  gem "rspec-rails", "~> 3.7.0"
  gem "rubocop"
  gem "spring"
end
