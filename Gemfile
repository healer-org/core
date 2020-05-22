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

gem "dotenv-rails", "~> 2.7.5"
gem "json-schema", "~> 2.8.1"
gem "mimemagic", "~> 0.3.3"
gem "paperclip", "~> 5.2.0"
gem "pg", "~> 1.2.1"
gem "rails", "~> 6.0.2.1"
gem "rake", "~> 13.0.1"

group :development, :test do
  gem "puma", "~> 4.3.5"
end

group :development, :test do
  gem "byebug"
  gem "faker"
  gem "rubocop"
  gem "spring"
end

group :test do
  gem "database_cleaner", "~> 1.7.0"
  gem "rspec-rails", "~> 3.9.0"
  gem "guard-rspec", "~> 4.7.3"
end
