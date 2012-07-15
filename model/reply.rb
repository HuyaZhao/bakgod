# encoding: utf-8
module BakGod
  module Model
    class Reply
      include ::Virtus

      attribute :id,         ::Integer
      attribute :topic_id,   ::Integer
      attribute :user_id,    ::Integer # 回复者 id
      attribute :content,    ::String
      attribute :created_at, ::Time
      attribute :updated_at, ::Time
      attribute :the_where,  ::Integer  # 某个主题的第几个回复


      def initialize(topic_id, attrs = nil)
        @topic_id = topic_id.to_i
        super(attrs)
      end

      def storge_key
        "bbs:topics:#{topic_id}:replies"
      end

      def content=(str)
        @content = ::Sanitize.clean(
            str, ::BakGod::Lib::Helper::HTML_SANITIZER_BASIC
        )
      end

      def value
        ::Yajl.dump(self.attributes)
      end

      def self.find(topic_id, id)
        reply     = self.new(topic_id)
        query_key = reply.storge_key
        if $redis.exists(query_key)
          value = $redis.hget query_key, id
          reply.attributes = ::Yajl.load(value) if value
          reply
        end
      end

      # @params[array]
      #  获得传进来所有回复对应的用户
      def self.users(replies = [])
        user = User.new
        user_array = $redis.pipelined do
          replies.each do |r|
            $redis.hgetall user.storge_key(r.user_id)
          end
        end
        user_array.map do |u|
          instance = User.new
          instance.attributes = u
          instance
        end
      end

      # params[ntf_user] 为主题作者id
      def notification(ntf_user, attrs = {})
        # 通知主题作者 notification the topic owner
        # 如果主题作者跟回复者一样，不通知
        if ntf_user != self.user_id
          create_notification(ntf_user, attrs.update(type: 0))
        end

        notification_users = @content.scan(/@(\w{3,20})/).uniq
        unless notification_users.empty?
          # 通知回复中@到的用户
          new_attrs = attrs.update(type: 1)
          # 拿到要通知的所有用户ID
          ids = $redis.pipelined do
            notification_users.each do |username|
              $redis.hget(AccountUsername.class_key, username)
            end
          end
          ids.each { |userid| create_notification(userid, new_attrs) }
        end
      end

      def save
        auto_increment
        set_times
        if $redis.hset(storge_key, @id, self.value)
          self
        end
      end



    private

      def auto_increment
        @id ||= $redis.incr("incr##{self.storge_key}")
      end

      def set_times
        time = self.created_at = Time.now unless self.created_at
        self.updated_at = time unless self.updated_at
      end

      def create_notification(userid, attrs = {})
        Notification.new(userid, attrs).save
      end

    end # class Reply
  end # module Model
end # module BakGod