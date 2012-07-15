# encoding: utf-8
module Bigman
  module Validation

    def valid?
      errors.clear
      validate
      errors.empty?
    end

    def validate
    end

    def errors
      @errors ||= Hash.new { |hash, key| hash[key] = [] }
    end


  private
    def validate_number_of(property)
      unless self.__send__(property) =~ /\A\d+\z/
        errors[property].push :not_number
      end
    end

    def validate_present_of(property)
      # blank? 方法来自active_support
      # 如果validation.rb单独使用,这里应该require blank.rb
      if self.__send__(property).blank?
        errors[property].push :not_blank
      end
    end

    def validates_confirmation_of(property, conf_property)
      if self.__send__(property) != self.__send__(conf_property)
        errors[conf_property].push :not_confirmation
      end
    end

    def validates_format_of(property, regexp)
      if self.__send__(property) !~ regexp
        errors[property].push :not_matching
      end
    end

    def validates_length_of(property, option = {})
      length = self.__send__(property).to_s.length
      unless option.fetch(:min) <= length && option.fetch(:max) >= length
        errors[property].push :not_in_limits
      end
    end

    def validates_uniqueness_of(property, &block)
      if block.call
        errors[property].push :has_existed
      end
    end

  end # module Validation
end # module Bigman