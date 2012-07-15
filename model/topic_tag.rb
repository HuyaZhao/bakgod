# encoding: utf-8
module BakGod
  module Model
    class TopicTag
      # 储存主题标签,这里的value自动生成
      # bbs:topics:tags => { 'ruby' =>1, 'nodejs' =>2 }

      # 将标签对应的主题存取
      # bbs:topics:tags:1  => [3, 9, 80, 900]
      #
      include ::Bigman::Rhash::Single

      def self.class_key
        'bbs:topics:tags'
      end

      #

    end # class TopicTag
  end # module Model
end # module BakGod