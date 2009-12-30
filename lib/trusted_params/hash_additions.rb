module TrustedParams
  module HashAdditions
    def trust(*attribute_names)
      if attribute_names.empty?
        @trusted_attributes = :all
        each_key { |k| self[k].trust if self[k].kind_of? Hash }
      else
        @trusted_attributes = attribute_names.map(&:to_sym)
        attribute_names.each do |attribute_name|
          self[attribute_name].trust if self[attribute_name].kind_of? Hash
        end
      end
      self
    end
    
    def trusted?(attribute_name)
      if defined?(@trusted_attributes)
        @trusted_attributes == :all || @trusted_attributes.include?(attribute_name.to_sym)
      end
    end

    def copy_trusted_attributes_to(other_hash)
      other_hash.instance_variable_set('@trusted_attributes', @trusted_attributes) if defined?(@trusted_attributes)
    end
  end
end

# I would prefer not setting this in all hashes, but it is the easiest solution at the moment.
class Hash
  include TrustedParams::HashAdditions
end

# override "dup" method because it doesn't carry over trusted attributes
# I wish there was a better way to do this...
class HashWithIndifferentAccess
  def dup_with_trusted_attributes
    returning(dup_without_trusted_attributes) do |hash|
      copy_trusted_attributes_to(hash)
      each { |key, value| value.copy_trusted_attributes_to(hash[key]) if value.is_a?(Hash) }
    end
  end
  alias_method_chain :dup, :trusted_attributes
end

module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Hash #:nodoc:
      module Keys
        # Return a new hash with all keys converted to strings.
        def stringify_keys_with_trusted_attributes
          returning(stringify_keys_without_trusted_attributes) { |hash| copy_trusted_attributes_to(hash) }
        end
        alias_method_chain :stringify_keys, :trusted_attributes
      end
    end
  end
end
