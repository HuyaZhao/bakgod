source "https://rubygems.org"

group :production do
  gem 'sinatra', require: 'sinatra/base'
  gem 'virtus'
  gem 'redis'
  gem 'dalli'
  gem 'rack-flash3', require: 'rack-flash'
  gem 'tilt'
  gem 'erubis'
  gem 'yajl-ruby', require: 'yajl'
  gem 'sanitize'
  gem 'json', require: 'json/ext'
  #gem 'mini_magick'
  #gem 'i18n'
  gem 'puma'
end

group :development do
  gem 'sinatra-contrib', require: 'sinatra/reloader'
end

group :test do
  gem 'minitest'
  gem 'guard-minitest'
end
