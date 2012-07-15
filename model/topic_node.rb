# encoding: utf-8
module BakGod
  module Model
    class TopicNode
      # store the topic node( category )
      #
      # bbs:topics:nodes => {'ruby' =>1, 'rails' =>2}
      # 后台操作。生成好类别(节点)
      include ::Bigman::Rhash::Single

      def self.class_key
        'bbs:topics:nodes'
      end

      def self.all
        $redis.hgetall class_key
      end

    end
  end # module Model
end # module BakGod