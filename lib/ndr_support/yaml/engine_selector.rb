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
# ================================================================
# TODO: This logic is likely redudant now:
#       The transition to Ruby 2.0+ is likely to be smoothest
#       if we move directly to using `psych`, and start using
#       immediately a rbenv-driven fallback mechanism for handling
#       unparseable YAML.
# ================================================================
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
      def yaml_loader_for(_string)
        PSYCH
      end

      # Returns the YAML engine that should be used
      # for emitting new YAML.
      def yaml_emitter
        PSYCH
      end

      private

      # TODO: code out once we're on 2.0+ everywhere.
      def syck_available?
        !SYCK.nil?
      end

      def psych_available?
        !PSYCH.nil?
      end
    end
  end
end
