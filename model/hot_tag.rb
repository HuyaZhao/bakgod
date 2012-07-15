# encoding: utf-8
module BakGod
  module Model
    class HotTag
      # 根据发表主题的标签来存取热门标签
      def self.class_key
        'bbs:hot:tags'
      end

      def self.incrby(increment, member)
        $redis.zincrby(class_key, increment, member)
      end

      # 按照主题的多少取出
      # 标签1被10个主题提到,标签2被6个主题提到
      # 只取前30个
      def self.tags
        $redis.zrevrange(class_key, 0, 30)
      end

    end # class HotTag
  end # module Model
end # module BakGod