# encoding: utf-8
module Bigman
  module Support
    module Instance

      def page(page = 1)
        page     = page.to_i
        per_page = @kclass.const_defined?(:PER_PAGE) ? @kclass::PER_PAGE : 0
        @from    = (page - 1) * per_page
        @to      = page * per_page - 1
        self
      end

      def from; @from || 0  ;end
      def to;   @to   || -1 ;end

      def query
        if @has_one
          kclass_instance.zip self.has_one_instance
        else
          kclass_instance
        end
      end

      #def kclass_instance
      #  result = []
      #  self.get_redis_data.each do |id|
      #    ki = @kclass.new
      #    ki.attributes = ki.load($redis.get("#{@kclass.class_key}:#{id}"))
      #    result.push ki
      #  end
      #  result
      #end


      # 一次取回要查询的类数据
      def kclass_result
        @query_array = self.ids
        $redis.pipelined do
          @query_array.each { |id|
            $redis.get("#{@kclass.class_key}:#{id}")
          }
        end
      end

      # 实例化
      def kclass_instance
        kclass_result.map do |attribute|
          instance = @kclass.new
          instance.attributes = instance.load(attribute)
          instance
        end
      end

      # 类的附属属性
      def has_one_result
        instance = @has_one.new
        $redis.pipelined do
          @query_array.each { |id|
            $redis.hgetall(instance.storge_key(id))
          }
        end
      end

      def has_one_instance
        has_one_result.map do |attribute|
          instance = @has_one.new
          instance.attributes = attribute
          instance
        end
      end

    end
  end # module Support
end # module Bigman