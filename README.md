![](https://github.com/sisk/healer-core/blob/master/app/assets/images/healer_logo_trans.png)

# healer-core

This is Healer's core API. Its serves JSON to provide information about medical teams, patients, clinical case work, and appointment scheduling.

## What is Healer?
Healer is an emerging nonprofit technology initiative facilitating the efforts of volunteer medical workers worldwide.

## Where can I get more information?
This document is pretty much it for right now. If you'd like to get in touch with a human, [look here](https://github.com/sisk).

# Development
## Requirements
* Ruby 2.5.3
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
