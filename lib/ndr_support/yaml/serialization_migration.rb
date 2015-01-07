require 'yaml'
require 'ndr_support/utf8_encoding'
require 'ndr_support/yaml/engine_selector'

# Lightweight wrapper around YAML serialization, to provide any
# necessary support for YAML engines and string encodings.
module YAML
  module SerializationMigration
    include UTF8Encoding
    include YAML::EngineSelector

    # Wrapper around: YAML.load(string)
    def load_yaml(string)
      ensure_utf8!(string)

      # Achieve same behaviour using `syck` and `psych`:
      unescape_special_characters!(string)

      loader = yaml_loader_for(string)
      object = loader.load(string)

      # Ensure that any string related to the object
      # we've loaded is also valid UTF-8.
      ensure_utf8_object!(object)
    end

    # Wrapper around: YAML.dump(object)
    def dump_yaml(object)
      yaml_emitter.dump(object)
    end

    private

    # Within double quotes, YAML allows special characters.
    # While `psych` emits UTF-8 YAML, `syck` double escapes
    # higher characters. We need to unescape any we find:
    def unescape_special_characters!(string)
      # Replace any encoded hex chars with their actual value:
      string.gsub!(/\\x([0-9A-F]{2})/) { [$1].pack("H2") }
      ensure_utf8!(string)
    end
  end
end
