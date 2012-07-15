# encoding: utf-8

# Rstring 为redis里的string类型
# 存取的key，需要自己定义类方法class_key
module Bigman
  module Rstring
    def self.included(base)
      base.module_eval do
        base.extend ClassMethods
        base.__send__(:include, InstanceMethods)
      end
    end
    private_class_method :included

    module ClassMethods
      def find(num)
        instance = self.new
        data     = $redis.get("#{self.class_key}:#{num}")
        if data
          instance.attributes = instance.load(data)
          instance.__send__(:is_new=, false)
          instance
        else
          raise ::Bigman::RecordNotFound
        end
      end
    end # module ClassMethods

    module InstanceMethods

      def initialize(attributes = nil)
        super(attributes)
        @is_new = true
      end

      def is_new?; @is_new; end

      def before_save;end

      # 获取类class_key
      def class_key
        self.class.class_key
      end

      # 存取到redis里去的key
      def storge_key
        "#{self.class_key}:#{self.id}"
      end

      # 序列化数据
      def dump
        ::Yajl.dump self.attributes
      end

      # 还原数据
      def load(data)
        ::Yajl.load data
      end

      # @params[Hash]
      #   { key: :key, score: 1 }
      #  the key must be the class method
      #  the score must be the instance method
      # @return[self]
      def sorted_set(options = {}, &block)
        key        = self.class.__send__(:"key_by_#{options.fetch(:key)}")
        score      = determine_score_type options
        key, score = block.call(key, score) if block
        ::Bigman::RsortedSet::Member.new(key, score, self.id).save
        self
      end

      # @param[hash]
      #   类方法跟参数
      # { class_method: :test, params: 1 }
      def lpush_save(option = {})
        rlist_instance(option).save
        self
      end

      def rpush_save(option = {})
        rlist_instance(option).rsave
        self
      end

      def save
        unless self.valid?
          raise ::Bigman::RecordInvalid, ::Yajl.dump(self.errors)
        end
        before_save
        auto_increment
        set_default_time
        $redis.set(storge_key, dump)

        self.__send__(:is_new=, false) if is_new?
        self
      end

    private
      def auto_increment
        self.id ||= $redis.incr("incr##{self.class_key}")
      end

      def set_default_time
        if self.respond_to?(:created_at)
          time = self.created_at = Time.now
        end
        self.updated_at = time if self.respond_to?(:updated_at)
      end

      def determine_score_type(options)
        type = options.fetch(:score)
        case type
        when ::Numeric
          type
        when ::Symbol
          self.__send__(:"score_by_#{type}")
        else
          self.__send__(:"score_by_#{options[:key]}") { type }
        end
      end

      def rlist_instance(option)
        ::Bigman::Rlist::Member.new(
            kclass:       self.class,
            class_method: option[:class_method],
            params:       option[:params],
            value:        self.id
        )
      end

      def is_new=(bool); @is_new = bool; end

    end # module InstanceMethods
  end # module Rstring
end # module Bigman