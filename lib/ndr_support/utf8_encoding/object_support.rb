require 'ndr_support/utf8_encoding'

# Allows any object (if supported) to have all related
# strings coerced in place to UTF-8.
module UTF8Encoding
  module ObjectSupport
    # Recursively ensure the correct encoding is being used:
    def ensure_utf8_object!(object)
      case object
      when String
        ensure_utf8!(object)
      when Hash
        ensure_utf8_hash!(object)
      when Array
        ensure_utf8_array!(object)
      else
        object
      end
    end

    # Ensures all values of the given `hash` are UTF-8, where possible.
    def ensure_utf8_hash!(hash)
      hash.each_value { |value| ensure_utf8_object!(value) }
    end

    # Ensures all elements of the given `array` are UTF-8, where possible.
    def ensure_utf8_array!(array)
      array.each { |element| ensure_utf8_object!(element) }
    end
  end
end
