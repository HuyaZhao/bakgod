# encoding: utf-8
module BakGod
  module Model
    class AccountUsername
      include ::Bigman::Rhash::Single

      def self.class_key
        'bbs:accounts_usernames'
      end

    end # class AccountUsername
  end # module Model
end # module BakGod