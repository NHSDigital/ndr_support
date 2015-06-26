require File.join(File.dirname(__FILE__), 'utf8_encoding', 'control_characters')
require File.join(File.dirname(__FILE__), 'utf8_encoding', 'object_support')

# Provides encoding support to be used for file / rawtext handling.
module UTF8Encoding
  include ControlCharacters
  include ObjectSupport

  # Raised when we cannot ensure a string is valid UTF-8
  class UTF8CoercionError < EncodingError; end

  # Our known source encodings, in order of preference:
  AUTO_ENCODINGS = %w( UTF-8 UTF-16 Windows-1252 )
  # How should unmappable characters be escaped, when forcing encoding?
  REPLACEMENT_SCHEME = lambda { |char| '0x' + char.ord.to_s(16).rjust(2, '0') }

  # Returns a new string with valid UTF-8 encoding,
  # or raises an exception if encoding fails.
  def ensure_utf8(string, source_encoding = nil)
    ensure_utf8!(string.dup, source_encoding)
  end

  # Attempts to encode `string` to UTF-8, in place.
  # Returns `string`, or raises an exception.
  def ensure_utf8!(string, source_encoding = nil)
    # A list of encodings we should try from:
    candidates = source_encoding ? Array.wrap(source_encoding) : AUTO_ENCODINGS

    # Attempt to coerce the string to UTF-8, from one of the source
    # candidates (in order of preference):
    apply_candidates!(string, candidates)

    unless string.valid_encoding?
      # None of our candidate source encodings worked, so fail:
      fail(UTF8CoercionError, "Attempted to use: #{candidates}")
    end

    string
  end

  # Returns a UTF-8 version of `string`, escaping any unmappable characters.
  def coerce_utf8(string, source_encoding = nil)
    coerce_utf8!(string.dup, source_encoding)
  end

  # Coerces `string` to UTF-8, in place, escaping any unmappable characters.
  def coerce_utf8!(string, source_encoding = nil)
    # Try normally first...
    ensure_utf8!(string, source_encoding)
  rescue UTF8CoercionError
    # ...before going back-to-basics, and replacing things that don't map:
    string.encode!('UTF-8', 'BINARY', :fallback => REPLACEMENT_SCHEME)
  end

  private

  def apply_candidates!(string, candidates)
    candidates.detect do |encoding|
      begin
        # Attempt to encode as UTF-8 from source `encoding`:
        string.encode!('UTF-8', encoding)
        # If that worked, we're done; otherwise, move on.
        string.valid_encoding?
      rescue EncodingError
        # If that failed really badly, move on:
        false
      end
    end
  end
end
