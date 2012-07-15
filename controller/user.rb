# encoding: utf-8
module BakGod
  class App < ::Sinatra::Base
    get('/signup') { erb :'users/signup' }
    get('/login')  { erb :'users/login' }

    post '/users/add' do
      canhandle do
        account = model('account').new(params['users']).save
        model('account_email').new(account.email, account.id).save
        account.lpush_save(class_method: :sort_by_time)

        model('user').new(
            account_id: account.id,
            username:   params['users']['username']
        ).save
        model('account_username').new(
            params['users']['username'], account.id
        ).save

        session[:user_id] = account.id.to_i
      end

      if @client_errors
        redirect '/signup'
      else
        flash[:notice] = '注册成功'
        redirect '/topics'
      end
    end

    post '/sessions' do
      canhandle do
        ae = model('account_email').find_by_field(params['users']['email'])
        if ae
          account = model('account').find(ae.value)
          if account && account.authenticate?(params['users']['password'])
            session[:user_id] = ae.value.to_i
          end
        end
      end

      if session[:user_id]
        flash[:notice] = '登录成功!'
        redirect '/topics'
      else
        flash[:notice] = '帐号或密码不正确!'
        redirect '/login'
      end
    end

    get('/logout') do
      is_login
      session[:user_id] = nil
      redirect '/topics'
    end

    get '/users/profile' do
      is_login
      @user = model('user').find current_user.account_id
      erb :'users/profile'
    end

    post '/users/profile' do
      is_login
      canhandle do
        @user = model('user').find current_user.account_id
        @user.updates username: params['username'],description: params['description']
      end

      return_data = if @client_errors
                      {msg: 'wrong'}
                    else
                      {msg: 'ok'}
                    end
      return_data.to_json
    end

    post '/users/password' do
      is_login
      canhandle do
        account = model('account').find current_user.account_id
        if account.authenticate?(params['old_pwd'])
          account.password              = params['new_pwd']
          account.password_confirmation = params['re_pwd']
          account.save
        else
          @client_errors = '旧密码输入错误'
        end
      end

      return_data = if @client_errors
                      {msg: 'wrong'}
                    else
                      {msg: 'ok'}
                    end
      return_data.to_json
    end

    post '/users/avatar' do
      is_login
      canhandle do
        @user = model('user').find current_user.account_id
        @user.upload_avatar = params['file']
      end

      return_data = if @client_errors
                      {msg: 'wrong', errormsg: @client_errors}
                    else
                      {msg: 'ok', filename: @user.avatar_path}
                    end
      return_data.to_json
    end

    get '/members/:id' do
      canhandle do
        @member  = model('user').find params[:id]
        @topics  = @member.topics
        @replies = @member.replies
      end
      redirect '/topics' if @client_errors
      erb :'users/index'
    end



  end
end