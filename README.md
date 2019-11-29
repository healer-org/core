![](https://github.com/sisk/healer-core/blob/master/app/assets/images/healer_logo.png)

# healer-core

This is the core API for [Healer](https://www.healer.global). It provides utility to facilitate medical teams, patients, clinical case work, and appointment scheduling for humanitarian and missionary groups.

# Development
## Requirements
* Ruby 2.6.5
* Bundler
* Docker

## Getting Started
* `cp .env.example .env`
* `bundle install`
* `docker-compose -f docker-compose.dev.yml up`
* `bin/rake db:create:all`
* `bin/rake db:migrate`
* Visit `http://localhost:9292`

## Running Tests
* `bin/rake`
