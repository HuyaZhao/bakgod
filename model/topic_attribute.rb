# encoding: utf-8
module BakGod
  module Model
    class TopicAttribute
      include ::Virtus
      include ::Bigman::Rhash::Multi
      include ::Bigman::Validation

      attribute :topic_id,            ::Integer
      attribute :node_id,             ::Integer # （分类）节点
      attribute :user_id,             ::Integer
      attribute :tags,                ::String
      attribute :created_at,          ::Time
      attribute :updated_at,          ::Time
      attribute :last_reply_user_id,  ::Integer
      attribute :last_reply_username, ::String
      attribute :last_reply_time,     ::Time
      attribute :click_count,         ::Integer, default: 0
      attribute :reply_count,         ::Integer, default: 0

      def storge_key(num = nil)
        "bbs:topics:#{num ? num.to_i : self.topic_id}:attributes"
      end

      # 还原标签数组
      def format_tags
        ::Yajl.load @tags
      end

      # @param[str]
      #   将标签转化成数组,再序列化保存
      def tags=(str)
        begin
          ::Yajl.load(str)
          @tags = str
        rescue ::Yajl::ParseError
          tags = str.split(/[,，\s]+/).uniq
          @tags = ::Yajl.dump tags
        end
      end

      # 发表该主题的用户
      def user
        User.find self.user_id
      end

      def topic
        Topic.find self.topic_id
      end

      def validate
        validate_present_of :topic_id
        validate_present_of :node_id
        validate_present_of :user_id
        validate_present_of :tags
      end


    end # class TopicAttribute
  end # module Model
end # module BakGod