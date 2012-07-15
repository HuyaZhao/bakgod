# encoding: utf-8
module BakGod
  class App < ::Sinatra::Base

    get '/notifications' do
      is_login
      user_id = current_user.account_id
      @counts = model('notification').count(user_id)
      @notifs = model('notification').all(user_id) if @counts > 0
      erb :'notification/index'
    end

    get '/notifications/destroy' do
      is_login
      status = model('notification').destroy(current_user.account_id)

      if status == 1
        {msg: 'ok'}.to_json
      else
        {msg: 'wrong'}.to_json
      end
    end

    get '/notifications/:nid/delete' do
      is_login
      status = model('notification').delete(
          current_user.account_id, params[:nid]
      )

      if status == 1
        {msg: 'ok'}.to_json
      else
        {msg: 'wrong'}.to_json
      end
    end


  end
end