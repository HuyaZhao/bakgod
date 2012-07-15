# encoding: utf-8

unless defined?($redis)
  $redis = ::Redis.new(host: '127.0.0.1', port: 6379)
end

require 'yajl'
require_relative 'support/instance'

require_relative 'bigman/rstring'
require_relative 'bigman/rhash_single'
require_relative 'bigman/rhash_multi'
require_relative 'bigman/rsorted_set'
require_relative 'bigman/rlist'

module Bigman
  class RecordNotFound < ::StandardError;end
  class RecordInvalid < ::StandardError; end
end