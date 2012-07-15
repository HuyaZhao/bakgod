# encoding: utf-8
module BakGod
  module Model
    class Topic
      include ::Virtus
      include ::Bigman::Rstring
      include ::Bigman::Validation

      PER_PAGE = 20

      attribute :id,      ::Integer
      attribute :title,   ::String
      attribute :content, ::String

      def self.class_key
        'bbs:topics'
      end

      def self.sort_by_time
        'bbs:topics:sort_by_created_at'
      end

      def self.key_by_updated_at
        'bbs:topics:sort_by_updated_at'
      end

      def score_by_updated_at
        yield.to_f
      end

      # 按照创建时间将主题存在各个分类（节点）里
      def self.node_by_created_at(node_id)
        "bbs:topics:nodes:#{node_id}"
      end

      # 按照创建时间将主题存在各个标签里
      def self.tags_by_created_at(tag_id)
        "bbs:topics:tags:#{tag_id}"
      end

      # 获得传进来所有主题的用户
      def self.users(topics = [])
        user       = User.new
        user_array = $redis.pipelined do
                       topics.each do |topic|
                         $redis.hgetall user.storge_key(topic[1].user_id)
                       end
                     end
        user_array.map do |u|
          instance = User.new
          instance.attributes = u
          instance
        end
      end

      # @param[page]
      #  按照创建时间取出最新的主题
      def self.newest(page = 1)
        ::Bigman::Rlist::Member.new(
            kclass:       self,
            class_method: :sort_by_time,
            has_one:      TopicAttribute
        ).page(page).query
      end

      # 取出某个标签的所有主题
      def self.get_topics_by_tag(tagid, page = 1)
        ::Bigman::Rlist::Member.new(
            kclass:       self,
            class_method: :tags_by_created_at,
            params:       tagid,
            has_one:      TopicAttribute
        ).page(page).query
      end

      # 按照主题被回复的时间
      def self.get_topics_by_updated_time(page = 1)
        ::Bigman::RsortedSet::Collection.new(
            kclass:  self,
            key:     self.key_by_updated_at,
            has_one: TopicAttribute
        ).page(page).desc.query
      end

      # 取出某个节点的所有主题
      def self.get_topics_by_node(nodeid, page = 1)
        ::Bigman::Rlist::Member.new(
            kclass:       self,
            class_method: :node_by_created_at,
            params:       nodeid,
            has_one:      TopicAttribute
        ).page(page).query
      end

      # @params[array]
      # 按照创建时间将主题存在各个标签里
      def tags_save(tags)
        tags.each do |tag|
          tt = TopicTag.find_or_create(tag)
          self.lpush_save(class_method: :tags_by_created_at, params: tt.value)
          HotTag.incrby(1, tag)
        end
      end

      # @param[str]
      # @return[str]
      # 重写content=() 格式化string.
      def content=(str)
        @content = ::Sanitize.clean(
            str, ::BakGod::Lib::Helper::HTML_SANITIZER_BASIC
        )
      end

      # 获取某个主题下的所有回复(按照创建时间先后排序)
      # 暂时不考虑分页
      def get_replies_by_created_at
        reply   = Reply.new(self.id)

        results = $redis.hvals(reply.storge_key).map do |item|
          instance            = Reply.new(self.id)
          instance.attributes = ::Yajl.load(item)
          instance
        end
        results.sort_by { |r| r.id }
      end

      # 某个key是否存在
      def self.key_exists?(class_method, id)
        $redis.exists(self.__send__(class_method, id))
      end

      def validate
        validate_present_of :title
        validate_present_of :content
      end

    end # class Topic
  end # module Model
end # module BakGod