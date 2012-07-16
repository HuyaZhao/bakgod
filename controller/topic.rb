# encoding: utf-8
module BakGod
  class App < ::Sinatra::Base
    # Todo
    # 实例变量太多,后面要重构减少

    get('/topics/new') do
      is_login
      @nodes = model('topic_node').all
      erb :'topics/new'
    end

    post '/topics' do
      is_login

      canhandle do
        @topic           = model('topic').new(params['topics']).save
        @topic_attribute = model('topic_attribute').new(
            topic_id: @topic.id,
            node_id:  params['topics']['node'],
            user_id:  current_user.account_id,
            tags:     params['topics']['tags']
        ).save
      end
      redirect('/topics/new') if @client_errors

      # Todo
      # 这些创建完主题后需要更新的一些key 方法
      # 都可以放在after_save里去执行
      $redis.pipelined do
        @topic.lpush_save(class_method: :sort_by_time)
        @topic.sorted_set(key: 'updated_at', score: @topic_attribute.updated_at)
        @topic.lpush_save(class_method: :node_by_created_at, params: @topic_attribute.node_id)

        current_user.create_owner_topic(@topic.id)
      end
      # 将主题存到各个标签中去
      @topic.tags_save(@topic_attribute.format_tags)
      redirect '/topics'
    end

    # 按回复时间排序
    get '/topics' do
      @topics  = model('topic').get_topics_by_updated_time(params['page'] || 1)
      integration @topics
      erb :'topics/index'
    end

    # 按创建时间排序
    get '/topics/newest' do
      @topics  = model('topic').newest(params['page'] || 1)
      integration @topics
      erb :'topics/index'
    end

    # 标签主题
    get '/topics/tag/:tag' do
      tag      = model('topic_tag').find_by_field(params[:tag])
      redirect('/topics') unless tag

      page = params['page'] || 1
      @topics  = model('topic').get_topics_by_tag(tag.value, page)
      integration @topics
      erb :'topics/index'
    end

    # 节点主题
    get '/nodes/:id' do
      node = model('topic').key_exists? :node_by_created_at, params[:id]
      redirect('/topics') unless node

      page    = params['page'] || 1
      @topics = model('topic').get_topics_by_node(params[:id], page)
      integration @topics
      erb :'topics/index'
    end

    get '/topics/:id' do
      get_topic
      erb :'topics/show'
    end

    get '/topics/:id/notifications/:nid/read' do
      is_login
      get_topic
      model('notification').read(current_user.account_id, params[:nid])
      erb :'topics/show'
    end

  private
    def get_topic
      @topic           = model('topic').find params[:id]
      @topic_attribute = model('topic_attribute').find params[:id]
      @topic_attribute.incr('click_count', 1)
      @topic_user      = @topic_attribute.user
      
      @node            = model('topic_node').all.invert[@topic_attribute.node_id]	
      @replies         = @topic.get_replies_by_created_at
      @rusers          = model('reply').users(@replies)
    end

    def integration(topics)
      @users   = model('topic').users(topics)
      @nodes   = model('topic_node').all
      @hottags = model('hot_tag').tags
    end


  end
end
