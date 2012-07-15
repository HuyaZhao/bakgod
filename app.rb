# encoding: utf-8
require 'sinatra/content_for'
require 'rack/session/dalli'
module BakGod
  class App < ::Sinatra::Base
    disable :protection

    use ::Rack::Session::Dalli, :expire_after => 900
    use ::Rack::MethodOverride
    use ::Rack::Flash

    helpers ::Sinatra::ContentFor
    helpers ::BakGod::Lib::Helper

    get('/') { redirect '/topics' }


  private
    # Todo
    # 凡是在代码里有涉及到文字说明的,后面全部改成用i18n处理
    def canhandle
      yield
    rescue ::Bigman::RecordInvalid => e
      @client_errors = ::Yajl.load(e.message)
    rescue ::Bigman::RecordNotFound
      @client_errors = 'not found'
    rescue ::BakGod::Model::UpfileError
      @client_errors = '请上传大小在1M内的图片文件'
    rescue => e
      @client_errors = nil
    end

    def is_login
      redirect to('/login') unless login?
    end


  end # class App
end # module BakGod
require_relative 'controller/init'