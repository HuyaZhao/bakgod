# encoding: utf-8
module Bigman
  module RsortedSet
    class Member
      def initialize(key, score, member)
        @key      = key
        @score    = score
        @member   = member
      end

      def save
        $redis.zadd(@key, @score, @member)
      end
    end # class Member


    class Collection
      include ::Enumerable
      include ::Bigman::Support::Instance

      #   @param[kclass] 为要查询的类
      #   @param[key] 可以为symbol，或 string.
      # {
      #   kclass: Article,
      #   has_one: ArticleAttribute,
      #   key: :key_by_created_at
      #  }
      def initialize(options)
        @kclass  = options.fetch(:kclass)
        @has_one = options[:has_one]
        @key     = determine_type(options.fetch(:key))
      end

      def each
        return to_enum unless block_given?
        self.kclass_result.each do |attribute|
          instance = @kclass.new
          instance.attributes = attribute
          yield(instance)
        end
      end

      def desc
        @order = :desc
        self
      end

      def ids
        @order ? self.zrevrange : self.zrange
      end

      def zrange
        $redis.zrange(@key, from, to)
      end

      def zrevrange
        $redis.zrevrange(@key, from, to)
      end

    private
      def determine_type(type)
        case type
        when ::String
          type
        when ::Symbol
          @kclass.__send__(type)
        end
      end

    end # class Collection
  end # module RsortedSet
end # module Bigman