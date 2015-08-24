require 'yaml'
require 'ndr_support/utf8_encoding'
require 'ndr_support/yaml/engine_selector'

module NdrSupport
  module YAML
    # Lightweight wrapper around YAML serialization, to provide any
    # necessary support for YAML engines and string encodings.
    module SerializationMigration
      include UTF8Encoding
      include EngineSelector

      # Wrapper around: YAML.load(string)
      def load_yaml(string, coerce_invalid_chars = false)
        fix_encoding!(string, coerce_invalid_chars)

        # Achieve same behaviour using `syck` and `psych`:
        handle_special_characters!(string, coerce_invalid_chars)
        fix_encoding!(string, coerce_invalid_chars)

        loader = yaml_loader_for(string)
        object = loader.load(string)

        # Ensure that any string related to the object
        # we've loaded is also valid UTF-8.
        ensure_utf8_object!(object)

        # We escape all non-printing control chars:
        escape_control_chars_in_object!(object)
      end

      # Wrapper around: YAML.dump(object)
      def dump_yaml(object)
        yaml_emitter.dump binary_encode_any_high_ascii(object)
      end

      private

      # Makes `string` valid UTF-8. If `coerce` is true,
      # any invalid characters will be escaped - if false,
      # they will trigger an UTF8Encoding::UTF8CoercionError.
      def fix_encoding!(string, coerce)
        coerce ? coerce_utf8!(string) : ensure_utf8!(string)
      end

      # Within double quotes, YAML allows special characters.
      # While `psych` emits UTF-8 YAML, `syck` double escapes
      # higher characters. We need to unescape any we find:
      def handle_special_characters!(string, coerce_invalid_chars)
        # Replace any encoded hex chars with their actual value:
        string.gsub!(/((?:\\x[0-9A-F]{2})+)/) do
          byte_sequence = $1.scan(/[0-9A-F]{2}/)
          byte_sequence.pack('H2' * byte_sequence.length).tap do |sequence|
            fix_encoding!(sequence, coerce_invalid_chars)
          end
        end

        # Escape any null chars, as they can confuse YAML:
        string.gsub!(/\x00/) { UTF8Encoding::REPLACEMENT_SCHEME[0] }
      end
    end
  end
end
