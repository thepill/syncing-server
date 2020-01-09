source 'https://rubygems.org'

gem 'aws-sdk-sqs'
gem 'bcrypt'
gem 'dotenv-rails'
gem 'haml-rails'
gem 'jwt'
gem 'mysql2', '>= 0.3.13', '< 0.5'
gem 'rack-cors', require: 'rack/cors'
gem 'rails', '5.1.7'
gem 'rotp'
gem 'rubocop', '~> 0.79.0', require: false
gem 'secure_headers'
gem 'sentry-raven'
gem 'shoryuken'
gem 'whenever', require: false

# Used for 'respond_to' feature
gem 'responders', '~> 2.0'

group :development, :test, :docker_development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'listen'
  gem 'puma'
  gem 'rspec-rails'
  gem 'spring'

  # Used by Mailatcher
  gem 'mailcatcher'
  gem 'sinatra', github: 'sinatra'
end

group :development, :test do
  # Deployment tools
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger', '>= 0.2.0'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'capistrano-shoryuken', github: 'mobitar/capistrano-shoryuken'
  gem 'capistrano-sidekiq'
end

group :docker_development do
  gem 'sqlite3'
end
