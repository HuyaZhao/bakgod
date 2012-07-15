# encoding: utf-8
module BakGod
  class App < ::Sinatra::Base
    post '/api/check_email' do
      email = model('account_email').find_by_field params['email']
      if email
        {msg: 'ok'}.to_json
      else
        {msg: 'no'}.to_json
      end
    end
  end
end