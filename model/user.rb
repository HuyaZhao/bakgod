# encoding: utf-8
#require 'fileutils'
module BakGod
  module Model
    class UpfileError < ::StandardError; end
    class User
      include ::Virtus
      include ::Bigman::Rhash::Multi
      include ::Bigman::Validation

      MEDIUM_PATH = ::File.join(::ROOT_PATH, 'public/avatar/medium')
      THUMB_PATH  = ::File.join(::ROOT_PATH, 'public/avatar/thumb')
      AVATAR_SIZE = 1024000  # 上传的图片大小不能超过1M

      attribute :account_id,    ::Integer
      attribute :username,      ::String
      attribute :avatar_path,   ::String, default: 'default.jpg'
      attribute :description,   ::String
      attribute :created_at,    ::Time
      attribute :updated_at,    ::Time

      #def self.incr_key
      #  'bbs:accounts:users'
      #end

      def storge_key(num = nil)
        "bbs:accounts:#{num ? num.to_i : self.account_id}:users"
      end

      # list类型
      # 保存用户自己创建的主题 id
      def topic_key
        "bbs:users:#{self.account_id}:topics"
      end

      # Sorted set
      # 保存用户回复过的主题 id
      def reply_key
        "bbs:users:#{self.account_id}:replies"
      end

      def avatar(path)
        case path
        when :medium
          "/avatar/medium/#{self.avatar_path}"
        when :thumb
          "/avatar/thumb/#{self.avatar_path}"
        end
      end

      def avatar_name
        "#{account_id}_#{::Digest::MD5.hexdigest("#{account_id}")}"
      end

      def command(resize)
        "convert -resize '#{resize}>' -strip -quality 75%"
      end

      def upload_avatar=(file)
        unless file.is_a?(::Hash) && file[:tempfile].is_a?(::Tempfile)
          raise UpfileError
        end
        if !IMAGE_MIME_EXTENSIONS.include?(file[:type]) or
           file[:tempfile].size > AVATAR_SIZE
          raise UpfileError
        end

        # styles: { :medium => "100x100>", :thumb => "48x48>" }
        from_path = file[:tempfile].path
        filename  = self.avatar_name
        to_path1  = "#{MEDIUM_PATH}/#{filename}.png"
        to_path2  = "#{THUMB_PATH}/#{filename}.png"

        sub1 = ::BakGod::Lib::Uploader.run(
            command('100x100'), from_path, to_path1
        )
        sub2 = ::BakGod::Lib::Uploader.run(
            command('48x48'), from_path, to_path2
        )

        if sub1.exitstatus == 0 && sub2.exitstatus == 0
          self.update('avatar_path', "#{filename}.png")
          self
        else
          if ::File.exists?(to_path1)
            ::File.unlink(to_path1)
          elsif ::File.exists?(to_path2)
            ::File.unlink(to_path2)
          end
        end
      end

      def description=(desc)
        @description = ::Sanitize.clean(desc)
      end


      def validate
        validate_present_of :account_id
        #validates_length_of :username, min: 3, max: 20
        validates_format_of :username, /\A[\u4E00-\u9FA5\uf900-\ufa2d\w]{3,20}\z/
      end

      def valid_attrs(attrs)
        attrs.inject({}) do |result, item|
          self.__send__(:"#{item[0]}=", item[1])
          result[item[0]] = self.__send__(item[0])
          result
        end
      end

      def create_owner_topic(topic_id)
        $redis.lpush(self.topic_key, topic_id.to_i)
      end

      def create_owner_reply(score, topic_id)
        $redis.zadd(self.reply_key, score, topic_id)
      end

      def topics
        topic_ids = $redis.lrange(self.topic_key, 0, -1)
        get_topics topic_ids
      end

      def replies
        topic_ids = $redis.zrevrange(self.reply_key, 0, -1)
        get_topics topic_ids
      end

      # 用户的通知
      def notifications
        Notification.count self.account_id
      end

      private

      def get_topics(ids = [])
        topics    = $redis.pipelined do
          ids.each { |id| $redis.get("#{Topic.class_key}:#{id}") }
        end

        topics.map do |attribute|
          instance = Topic.new
          instance.attributes = instance.load(attribute)
          instance
        end
      end


    end # class User
  end # module Model
end # module BakGod