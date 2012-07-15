# encoding: utf-8
module Bigman
  module Rhash
    module Single
      def self.included(base)
        base.module_eval do
          base.extend ClassMethods
          base.__send__(:include, InstanceMethods)
        end
      end
      private_class_method :included

      module ClassMethods
        def find_by_field(field)
          instance = self.find(field)
          instance if instance.value
        end

        def find_or_create(field)
          instance = self.find(field)
          instance.value ? instance : instance.save
        end

        def find(field)
          self.new(field).tap do |instance|
            instance.value = $redis.hget(self.class_key, field)
          end
        end

        # @return[Hash]
        # 返回该key的所有内容
        def find_all
          $redis.hgetall(self.storge_key)
        end
      end # ClassMethods

      module InstanceMethods
        def before_save;end

        # @params[field]
        # @params[value]
        def initialize(field, value = nil)
          @field = field
          @value = value
        end

        def field;@field;end
        def value;@value;end
        def field=(field);@field = field;end
        def value=(value);@value = value;end

        def storge_key
          self.class.class_key
        end

        def save
          before_save
          @value = auto_increment unless @value
          self if $redis.hsetnx(storge_key, @field, @value)
        end

      private

        def auto_increment
          $redis.incr("incr##{self.storge_key}")
        end
      end # InstanceMethods
    end # module Single

  end # module Rhash
end # module Bigman