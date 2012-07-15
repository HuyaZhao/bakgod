# encoding: utf-8
module BakGod
  module Lib
    module Helper
      # html sanitize
      HTML_SANITIZER_BASIC = {
          :elements => %w[a ul ol li p strong img span u br em s],
          :attributes => {
              'a'    => ['href'],
              'img'  => ['align', 'alt', 'height', 'src', 'width'],
              'p' => ['style'],
              'span' => ['style'],
              'ul'   => ['style'],
              'ol'   => ['style']
          },
          :add_attributes => {
              'a' => {'rel' => 'nofollow'}
          }
      }

      # @params[String] for get a class
      # @return[Class]
      def model(name)
        na = name.to_s.split('_')
        result = if na.length > 1
                   na.inject('') { |k, i| k << i.capitalize }
                 else
                   name.to_s.capitalize
                 end
        ::BakGod::Model.const_get result.to_sym
      end

      # 是否登录
      def login?
        !!session[:user_id]
      end

      def current_user
        @current_user ||= model('user').find session[:user_id]
      end

    end # module Helper
  end # module Lib
end # module BakGod