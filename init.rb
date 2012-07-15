# encoding: utf-8
require 'bundler/setup'
require_relative 'config'

Bundler.require :production

case ENV['BBS_ENV']
  when 'development'
    Bundler.require :development
  when 'test'
    Bundler.require :test
    Bundler.require :development
end

require_relative 'lib/active_support/core_ext/object/blank'
require_relative 'lib/validation/validation'
require_relative 'gems/bigman/lib/bigman'
require_relative 'lib/helper'
require_relative 'lib/uploader'

Dir['./model/*'].each { |file| require(file) }

# redis client
$redis = Redis.new(host: '127.0.0.1', port: 6379)