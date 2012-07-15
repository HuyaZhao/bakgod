# encoding: utf-8
module BakGod
  module Model
    class AccountEmail
      include ::Bigman::Rhash::Single

      def self.class_key
        'bbs:accounts_emails'
      end

    end # class AccountEmail
  end # module Model
end # module BakGod