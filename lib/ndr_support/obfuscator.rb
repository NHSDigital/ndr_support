module NdrSupport
  # Contains logic for consistently obfuscating names and addresses
  # using a simple substitution cipher.
  module Obfuscator
    extend self

    # Set default obfuscation seed
    def setup(seed)
      @seed = seed
    end

    # Obfuscate a name or address, either with the given seed, or default seed
    def obfuscate(name, seed = nil)
      rnd = Random.new(seed || @seed)
      vowels = %w(A E I O U)
      consonants = ('A'..'Z').to_a - vowels
      digits = ('0'..'9').to_a
      dict = Hash[(vowels + consonants + digits).zip(vowels.shuffle(random: rnd) +
                                                     consonants.shuffle(random: rnd) +
                                                     digits.shuffle(random: rnd))]
      name.upcase.split(//).map { |s| dict[s] || s }.join
    end
  end
end
