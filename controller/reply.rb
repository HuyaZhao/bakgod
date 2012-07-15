# encoding: utf-8
module BakGod
  class App < ::Sinatra::Base
    post '/replies' do
      is_login
      userid     = current_user.account_id
      user_name  = current_user.username
      canhandle do
        ta    = model('topic_attribute').find params['topic_id']
        where = ta.reply_count + 1

        @reply           = model('reply').new(params['topic_id'],
                                              content: params['content']
                                             )
        @reply.user_id   = userid
        @reply.the_where = where
        @reply.save

        # topic_attribute update some property
        ta.updates(
            last_reply_user_id:  userid,
            last_reply_username: user_name,
            last_reply_time:     @reply.created_at,
            reply_count:         where
        )

        # 更新bbs:topics:sort_by_updated_at里的score
        ::Bigman::RsortedSet::Member.new(
            model('topic').key_by_updated_at,
            @reply.created_at.to_f, ta.topic_id
        ).save

        # 用户回复的主题
        current_user.create_owner_reply(@reply.created_at.to_f, @reply.topic_id)

        # notification
        @reply.notification(
            ta.user.account_id,
            user_id:   userid,
            username:  user_name,
            topic_id:  ta.topic_id,
            title:     ta.topic.title,
            the_where: where
        )
      end

      return_data = if @client_errors
                      {msg: 'wrong'}
                    else
                      {
                        msg: 'ok',
                        user: {
                            id:        userid,
                            username:  user_name,
                            avatar:    current_user.avatar_path
                        },
                        reply: {
                            id:         @reply.id,
                            content:    @reply.content,
                            created_at: @reply.created_at,
                            the_where:  @reply.the_where
                        }
                      }
                    end
      return_data.to_json
    end

    put '/replies/:id/delete' do
      is_login
      reply = model('reply').find(params['topic_id'], params['id'])
      if reply
        reply.content = '<s>该内容已被删除!</s>'
        reply.save
        {msg: 'ok'}.to_json
      else
        {msg: 'wrong'}.to_json
      end
    end

  end
end