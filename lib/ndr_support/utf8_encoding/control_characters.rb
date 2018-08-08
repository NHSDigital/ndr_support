require 'ndr_support/utf8_encoding'

module UTF8Encoding
  # Allows any supported object to have control characters
  # escaped, using standard replacement scheme.
  module ControlCharacters
    # The range of characters we consider:
    CONTROL_CHARACTERS = /[\x00-\x08]|[\x0b-\x0c]|[\x0e-\x1f]|\x7f/

    # Recursively escape any control characters in `object`.
    def escape_control_chars_in_object!(object)
      case object
      when String
        escape_control_chars!(object)
      when Hash
        escape_control_chars_in_hash!(object)
      when Array
        escape_control_chars_in_array!(object)
      else
        object
      end
    end

    # Returns a copy of `string`, with any control characters escaped.
    def escape_control_chars(string)
      escape_control_chars!(string.dup)
    end

    # Escapes in-place any control characters in `string`, before returning it.
    def escape_control_chars!(string)
      string.gsub!(CONTROL_CHARACTERS) do |character|
        UTF8Encoding::REPLACEMENT_SCHEME[character]
      end
      string
    end

    # Escape control characters in values of the given `hash`.
    def escape_control_chars_in_hash!(hash)
      hash.each_value { |value| escape_control_chars_in_object!(value) }
    end

    # Escape control characters in elements of the given `array`.
    def escape_control_chars_in_array!(array)
      array.each { |element| escape_control_chars_in_object!(element) }
    end
  end
end
