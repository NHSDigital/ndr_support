require 'yaml'

# Allows us to chose whether to use syck or psych
# depending on availablity and YAML source.
#
# Once on Ruby 1.9.3 across the board, we will need
# to start up-serialising that which loads differently
# between syck and psych, en-masse. Once we move to
# Ruby 2.0, we will be unable to use syck.
#
# Until then, we continue to emit with syck, and
# only read with psych if it is available
#
module NdrSupport
  module YAML
    module EngineSelector
      # Cautiously trigger loading of all available engines.
      # YAML seems to support multiple engines in weird ways,
      # See Plan.io issue #1971-#1 for an example of behaviour.
      if defined?(::YAML::ENGINE)
        begin
          engine = ::YAML::ENGINE.yamler
          ::YAML::ENGINE.yamler = 'psych'
          ::YAML::ENGINE.yamler = 'syck'
        ensure
          ::YAML::ENGINE.yamler = engine
        end
      end

      # Aliases to the engines.
      SYCK  = defined?(::Syck)  ? ::Syck  : nil
      PSYCH = defined?(::Psych) ? ::Psych : nil

      # Returns the YAML engine we should use
      # to load the given `string`.
      def yaml_loader_for(string)
        return PSYCH unless syck_available?

        # Only if both engines are available can we choose:
        emitted_by_psych?(string) ? PSYCH : SYCK
      end

      # Returns the YAML engine that should be used
      # for emitting new YAML.
      def yaml_emitter
        # Until all platforms have psych available,
        # we must continue to emit using syck.
        universal_psych_support? ? PSYCH : SYCK
      end

      private

      # TODO: code out once true.
      # !syck_available? forces this to be true for ruby 2.0 and above
      def universal_psych_support?
        false || !syck_available?
      end

      # We can make an educated guess as to whether it was psych
      # that created the given YAML string. These rules aren't
      # universally true (it is possible to engineer objects
      # that are dumped differently), but is a reasonable indicator.
      #
      # * Psych:
      #    starts with: '---\n'
      #    ends with:   '\n...\n'
      # * Syck:
      #    starts with: '--- \n'
      #    ends with:   '\n'
      #
      def emitted_by_psych?(string)
        (string =~ /\A---\n/) || (string =~ /\n[.]{3}\n\z/)
      end

      # TODO: code out once we're on 2.0+ everywhere.
      def syck_available?
        !SYCK.nil?
      end
    end
  end
end
