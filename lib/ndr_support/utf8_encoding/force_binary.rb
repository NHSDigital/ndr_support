module UTF8Encoding
  # Allows any supported object to have any high-ascii string
  # content to be force-encoded from UTF-8 to BINARY (/ASCII-8BIT).
  # This ensures that any serialisation to YAML, using Psych,
  # can be stored in other encodings. (Psych by default emits
  # UTF-8 YAML, which might not survive being stored in a Windows-1252
  # database, for example.)
  module ForceBinary
    # Recursively ensure the correct encoding is being used:
    def binary_encode_any_high_ascii(object)
      case object
      when String
        binary_encode_if_any_high_ascii(object)
      when Hash
        binary_encode_any_high_ascii_in_hash(object)
      when Array
        binary_encode_any_high_ascii_in_array(object)
      else
        object
      end
    end

    private

    # Returns a BINARY-encoded version of `string`, if is cannot be represented as 7bit ASCII.
    def binary_encode_if_any_high_ascii(string)
      string = ensure_utf8(string)
      string.force_encoding('BINARY') if string.bytes.detect { |byte| byte > 127 }
      string
    end

    # Ensures all values of the given `hash` are BINARY-encoded, if necessary.
    def binary_encode_any_high_ascii_in_hash(hash)
      Hash[hash.map { |key, value| [key, binary_encode_any_high_ascii(value)] }]
    end

    # Ensures all values of the given `array` are BINARY-encoded, if necessary.
    def binary_encode_any_high_ascii_in_array(array)
      array.map { |element| binary_encode_any_high_ascii(element) }
    end
  end
end
