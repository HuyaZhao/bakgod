# encoding: utf-8
module Bigman
  module Rhash
    module Multi
      def self.included(base)
        base.module_eval do
          base.extend ClassMethods
          base.__send__(:include, InstanceMethods)
        end
      end
      private_class_method :included

      module ClassMethods

        # 查找某个具体key的内容
        # @params[num] -->对应实例方法storge_key里的
        # @return[instance]
        def find(num)
          instance = self.new
          data     = $redis.hgetall(instance.storge_key(num.to_i))
          unless data.empty?
            instance.attributes = data
            return instance
          else
            raise ::Bigman::RecordNotFound
          end
        end

        def updates(id, attrs = {})
          obj = find id
          obj.updates(attrs)
        end

      end # ClassMethods

      module InstanceMethods
        def before_save;end
        def valid_attrs(hash); hash ;end

        def update(filed, value)
          $redis.hset(storge_key, filed, value)
          self
        end

        def updates(attrs = {})
          attrs = valid_attrs(attrs)
          $redis.hmset(storge_key, hash_to_array(attrs))
          self
        end

        def incr(field, value)
          $redis.hincrby(storge_key, field, value)
          self
        end

        # @数据数组化
        def array_data
          hash_to_array self.attributes
        end

        # @param[Hash]
        #   hash转array
        def hash_to_array(hash = {})
          hash.to_a.flatten.map(&:to_s)
        end

        def save
          unless self.valid?
            raise ::Bigman::RecordInvalid, ::Yajl.dump(self.errors)
          end
          before_save
          #auto_increment
          set_default_time
          $redis.hmset(storge_key, *array_data)
          self
        end

      private

        #def auto_increment
        #  self.id ||= $redis.incr("incr##{self.class.incr_key}")
        #end

        def set_default_time
          if self.respond_to?(:created_at)
            time = self.created_at = Time.now
          end
          self.updated_at = time if self.respond_to?(:updated_at)
        end

      end # InstanceMethods
    end # module Multi
  end # module Rhash
end # module Bigman