require 'ndr_support/password/constants'

module NdrSupport
  # Contains logic for checking and generating secure passwords,
  # in line with CESG guidelines.
  module Password
    include Constants

    extend self

    # Is the given `string` deemed a good password?
    # An additional `word_list` can be provided; its entries add only
    # minimally when considering the strength of `string`.
    #
    #   NdrSupport::Password.valid?('google password')    #=> false
    #   NdrSupport::Password.valid?(SecureRandom.hex(12)) #=> true
    #
    def valid?(string, word_list: [])
      string = prepare_string(string.to_s.dup)
      slug   = slugify(strip_common_words(string, word_list))

      meets_requirements?(slug)
    end

    # Generates a random #valid? password, using the 2048-word RFC1751 dictionary.
    # Optionally, specify `number_of_words` and/or `separator`.
    #
    #   NdrSupport::Password.generate #=> "sill quod okay phi"
    #   NdrSupport::Password.generate #=> "dint dale pew wane"
    #   NdrSupport::Password.generate #=> "rent jude ding gent"
    #
    #   NdrSupport::Password.generate(number_of_words: 6) #=> "dad bide thee glen road beam"
    #
    #   NdrSupport::Password.generate(separator: '-') #=> "jail-net-skim-cup"
    #
    # Raises a RuntimeError if a strong enough password was not produced:
    #
    #   NdrSupport::Password.generate(number_of_words: 1) #=>
    #     RuntimeError: Failed to generate a #valid? password!
    #
    def generate(number_of_words: 4, separator: ' ')
      attempts = 0

      loop do
        words = Array.new(number_of_words) do
          RFC1751_WORDS[SecureRandom.random_number(RFC1751_WORDS.length)].downcase
        end

        phrase = words.join(separator)
        return phrase if valid?(phrase)

        attempts += 1
        raise 'Failed to generate a #valid? password!' if attempts > 10
      end
    end

    private

    def meets_requirements?(string)
      string.length >= 6 && string.chars.uniq.length >= 5
    end

    def strip_common_words(string, common_words)
      common_words += COMMON_PASSWORDS

      # Try the longest common words first, in case some are substrings of others:
      common_words = common_words.sort_by(&:length).reverse

      common_words.each do |common_word|
        pattern = prepare_string(common_word)

        # Don't try to remove things that #slugify will be able to remove
        # at least as effectively: [#6950#note-12]
        next if slugify(pattern).length <= 2

        string.gsub!(pattern) { |word| word.chars.first + word.chars.last }
      end

      string
    end

    def slugify(string)
      input  = string.chars
      output = []

      until input.length.zero?
        sequence = [input.shift]
        sequence << input.shift while input.any? && no_added_value?(sequence.last, input.first)

        sequence.slice!(1..-2) # discard interior of sequence
        output.concat(sequence.uniq)
      end

      output.join
    end

    def no_added_value?(a, b)
      sequential?(a, b) || repeating?(a, b)
    end

    def repeating?(a, b)
      a == b
    end

    def sequential?(a, b, check_inverse: true)
      # avoid non-alphanumeric characters being considered for sequencing:
      # ';'.next #=> '<'
      return false unless sequencible?(a) && sequencible?(b)

      (a.next == b && b.length == 1) || (check_inverse && sequential?(b, a, check_inverse: false))
    end

    def sequencible?(string)
      /\A([a-z]|[0-9])\z/i =~ string
    end

    def prepare_string(string)
      string.downcase
    end
  end
end
