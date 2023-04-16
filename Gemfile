source 'https://rubygems.org'


gem 'dotenv-rails', '>= 2.2.2', groups: [:development, :test]

gem 'trix'
gem 'rails', '5.2.8.1'
gem 'devise', '~> 4.7.1'
gem 'puma', '>= 4.3.12'
gem 'jquery-rails', '>= 4.4.0'
gem 'nested_form'
gem 'active_hash'
gem 'sanitize', '>= 5.2.1'
gem 'gmaps4rails'
gem 'geocoder', '>= 1.6.1'
gem 'omniauth-meetup'
gem 'omniauth-facebook'
gem 'omniauth-twitter', '>= 1.3.0'
gem 'omniauth-github', '>= 2.0.0'
gem 'gravatar_image_tag'
gem 'simple_form', '>= 5.0.0'
gem 'rack-canonical-host', '>= 1.2.0'
gem 'icalendar'
gem 'pg' if ENV['FORCE_POSTGRES']

group :production do
  gem 'pg'
  gem 'rails_12factor'
  gem 'heroku_rails_deflate'
  gem 'newrelic_rpm'
  gem 'sentry-raven'
  gem 'rack-timeout'
end

gem 'handlebars_assets'
gem 'sass-rails', '>= 5.0.5'
gem 'coffee-rails', '>= 4.2.2'
gem 'uglifier'
gem 'bootstrap-sass', '>= 3.4.0'
gem 'font-awesome-rails', '>= 4.7.0.4'
gem 'jquery-ui-rails', '>= 6.0.0'
gem 'backbone-on-rails'
gem 'masonry-rails'

group :development do
  gem 'quiet_assets'
  gem 'rb-fsevent'
  gem "bullet"
  gem "heroku_san"
  gem "better_errors", ">= 2.8.0"
  gem "binding_of_caller"
  gem "byebug"
  gem 'rack-mini-profiler', '>= 0.10.1'
end

group :test, :development do
  gem 'jasmine'
  gem 'jasmine-jquery-rails'
  gem 'sqlite3'
  gem 'rspec-rails', '>= 3.5.0'
  gem 'rspec-collection_matchers'
  gem 'awesome_print'
end

group :test do
  gem 'webmock'
  gem "factory_girl_rails"
  gem 'capybara', '>= 2.5.0'
  gem "poltergeist"
  gem "launchy"
  gem 'shoulda-matchers'
  gem "faker"
  gem 'capybara-screenshot'
  # Remove after Rails 5: https://github.com/rails/rails/pull/18458
  gem 'test_after_commit'
end

source 'https://rails-assets.org' do
  gem 'rails-assets-DataTables'
  gem 'rails-assets-select2'

  group :test, :development do
    gem 'rails-assets-sinonjs'
  end
end
