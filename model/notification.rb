# encoding: utf-8
module BakGod
  module Model
    class Notification
      include ::Virtus

      attribute :user_id,  ::Integer
      attribute :username, ::String
      attribute :topic_id, ::Integer
      attribute :title,    ::String
      attribute :the_where,::Integer  # 第几个回复
      attribute :type,     ::Integer  # @ or reply
      attribute :readed,   ::Integer, default: 0  # 0表示未读，1表示已读

      def self.key(userid)
        "bbs:users:#{userid.to_i}:notifications"
      end

      #def self.all(userid)
      #  result = []
      #  all = $redis.hgetall key(userid)
      #  all.each_pair do |id, ntf|
      #    new_ntf  = ::Yajl.load(ntf)
      #    username = User.find(new_ntf['user_id']).username
      #    title    = Topic.find(new_ntf['topic_id']).title
      #    result.push [id, new_ntf.update('username' =>username, 'title' =>title)]
      #  end
      #  result
      #end

      def self.all(userid)
        result = []
        $redis.hgetall(key(userid)).each_pair do |id, ntf|
          result.push [id, ::Yajl.load(ntf)]
        end
        result.sort_by { |n| -n[0].to_i }
      end

      def self.count(userid)
        $redis.hlen key(userid)
      end

      def self.read(userid, nid)
        find = $redis.hget key(userid), nid
        if find
          $redis.hset(
              key(userid),
              nid,
              ::Yajl.dump(::Yajl.load(find).update('readed' => 1))
          )
        end
      end

      def self.delete(userid, nid)
        $redis.hdel key(userid), nid
      end

      def self.destroy(userid)
        $redis.del key(userid)
      end

      # @params[Integer]
      #   notification_user
      def initialize(ntf_user, attrs = nil)
        @user = ntf_user
        super(attrs)
      end

      def storge_key
        self.class.key(@user)
      end

      def field
        @field ||= $redis.incr("incr##{self.storge_key}")
      end

      def values
        ::Yajl.dump self.attributes
      end


      def save
        $redis.hset(storge_key, field, values)
      end

    end # class Notification
  end # module Model
end # module BakGod