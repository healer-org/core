FROM ruby:2.6-slim

COPY .ruby-version /app/
COPY Gemfile* /app/
WORKDIR /app

RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    file \
    libcurl4 \
    libpq-dev \
    libxml2-dev \
    libxslt-dev \
    tzdata && \
    bundle install && \
    apt-get remove -y --purge build-essential && \
    apt autoremove -y && \
        rm -rf /var/lib/apt/lists/*

RUN mkdir tmp
COPY . /app

EXPOSE 9292

CMD bin/puma
