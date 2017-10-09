# frozen_string_literal: true

ruby "2.3.3"
source "https://rubygems.org"

gem "bump-core",
    git: "https://github.com/gocardless/bump-core",
    tag: "v0.6.0"
gem "prius", "~> 2.0.0"
gem "rake"
gem "sentry-raven", "~> 2.6.3"
gem "sidekiq", "~> 5.0.5"
gem "sinatra"

group :development do
  gem "dotenv", require: false
  gem "foreman", "~> 0.84.0"
  gem "highline", "~> 1.7.8"
  gem "rspec", "~> 3.6.0"
  gem "rspec-its", "~> 1.2.0"
  gem "rubocop", "~> 0.50.0"
  gem "webmock", "~> 3.1.0"
end
