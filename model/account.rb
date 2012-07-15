# encoding: utf-8
require 'digest/md5'
module BakGod
  module Model
    class Account
      include ::Virtus
      include ::Bigman::Rstring
      include ::Bigman::Validation

      attribute :id,          ::Integer
      attribute :email,       ::String
      attribute :encrypt_pwd, ::String

      def self.class_key
        'bbs:accounts'
      end

      def self.sort_by_time
        'bbs:accounts:sort_by_created_at'
      end

      def password=(password)
        @password = password
      end
      def password; @password; end
      def password_confirmation; @password_confirmation; end

      def password_confirmation=(pwd_confirmation)
        @password_confirmation = pwd_confirmation
      end

      def authenticate?(password)
        self.encrypt_pwd == generate_encrypt_pwd(password)
      end

      def before_save
        self.encrypt_pwd = generate_encrypt_pwd(@password)
      end

      def validate
        validate_present_of :password
        validates_confirmation_of :password, :password_confirmation
        if self.is_new?
          validates_format_of :email, /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i
          validates_uniqueness_of(:email) {
            AccountEmail.find_by_field self.email
          }
        end
      end


    private
      def generate_encrypt_pwd(password)
        ::Digest::MD5.hexdigest(password)
      end


    end # class Account
  end # module Model
end # module BakGod