# encoding: utf-8
module Bigman
  module Rlist
    class Member
      include ::Bigman::Support::Instance

      def initialize(option = {})
        @kclass         = option.fetch(:kclass)
        @class_method   = option.fetch(:class_method)
        @params         = option[:params]
        @has_one        = option[:has_one]
        @value          = option[:value]
      end

      def key
        if @params
          @kclass.__send__(@class_method, @params)
        else
          @kclass.__send__(@class_method)
        end
      end

      def ids
        $redis.lrange(key, from, to)
      end

      def save
        $redis.lpush(key, @value)
      end

      def rsave
        $redis.rpush(key, @value)
      end

    end # class Member
  end # module Rstring
end # module Bigman