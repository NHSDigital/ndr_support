require 'yaml'
require 'ndr_support/utf8_encoding'

module NdrSupport
  module YAML
    # Lightweight wrapper around YAML serialization, to provide any
    # necessary support for YAML engines and string encodings.
    module SerializationMigration
      include UTF8Encoding

      # Classes we routinely allow to be included in our YAML serialisations, automatically
      # accepted by load_yaml
      YAML_SAFE_CLASSES = [Date, DateTime, Time, Symbol].freeze

      # Set list of YAML safe classes, or :unsafe to use unsafe load
      def yaml_safe_classes=(yaml_safe_classes)
        @yaml_safe_classes = yaml_safe_classes
      end

      def yaml_safe_classes
        @yaml_safe_classes || YAML_SAFE_CLASSES
      end

      # Allow emitted YAML to contain UTF-8 characters
      # Defaults to true. (Defaulted to false in ndr_support versions < 6)
      def utf8_storage=(utf8_storage)
        @utf8_storage = utf8_storage
      end

      def utf8_storage
        return @utf8_storage if @utf8_storage == false

        true # New ndr_support default for versions >= 6, previously false
      end

      # Wrapper around: YAML.load(string)
      def load_yaml(string, coerce_invalid_chars = false) # rubocop:disable Style/OptionalBooleanParameter
        fix_encoding!(string, coerce_invalid_chars)

        # Achieve same behaviour using `syck` and `psych`:
        handle_special_characters!(string, coerce_invalid_chars)
        fix_encoding!(string, coerce_invalid_chars)

        # TODO: Bump NdrSupport major version, and switch to safe_load by default
        object = if yaml_safe_classes == :unsafe
                   unless Psych::VERSION.start_with?('3.')
                     raise(SecurityError, 'Unsafe YAML no longer supported')
                   end

                   Psych.load(string)
                 else
                   Psych.safe_load(string, permitted_classes: yaml_safe_classes)
                 end

        # Ensure that any string related to the object
        # we've loaded is also valid UTF-8.
        ensure_utf8_object!(object)

        # We escape all non-printing control chars:
        escape_control_chars_in_object!(object)
      end

      # Wrapper around: YAML.dump(object)
      def dump_yaml(object)
        return Psych.dump(object) if utf8_storage

        # Psych produces UTF-8 encoded output; historically we
        # preferred YAML that can be safely stored in stores with
        # other encodings. If #load_yaml is used, the binary
        # encoding of the object will be reversed on load.
        Psych.dump binary_encode_any_high_ascii(object)
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
      # Both `psych` and `syck` escape lower control characters.
      def handle_special_characters!(string, coerce_invalid_chars)
        return unless string.start_with?('---') # Only handle YAML that is not JSON

        # Replace any encoded hex chars with their actual value:
        string.gsub!(/(?<!\\)((?:\\\\)*)((?:\\x[0-9A-F]{2})+)/) do
          # We use negative lookbehind and the first capturing group to skip over
          # properly escaped backslashes
          prefix = ::Regexp.last_match(1) # Prefix is an even number of backslashes
          byte_sequence = ::Regexp.last_match(2).scan(/[0-9A-F]{2}/)
          prefix + byte_sequence.pack('H2' * byte_sequence.length).tap do |sequence|
            fix_encoding!(sequence, coerce_invalid_chars)
          end
        end

        # Re-escape any non-printing control characters,
        # as they can break the YAML parser:
        escape_control_chars_in_object!(string)
      end
    end
  end
end
