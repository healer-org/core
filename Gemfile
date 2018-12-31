source "https://rubygems.org"

ruby File.read(
  File.expand_path(
    File.join(
      File.dirname(__FILE__),
      ".ruby-version"
    )
  )
).split("-").last.chomp

gem "rails", "~> 5.1"
gem "json-schema"

gem "paperclip", "~> 5.1"

gem "pg"

group :development, :test do
  gem "spring"
  gem "rspec-rails", "~> 3.7.0"
  gem "database_cleaner", "~> 1.6.0"
  gem "faker"
  gem "byebug"
  gem "rubocop"
end
