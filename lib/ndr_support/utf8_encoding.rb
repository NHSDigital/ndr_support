require File.join(File.dirname(__FILE__), 'utf8_encoding', 'object_support')

# Provides encoding support to be used for file / rawtext handling.
# Degrades gracefully on Ruby 1.8.7, where there is no encoding support.
module UTF8Encoding
  include UTF8Encoding::ObjectSupport

  # Backfill for basic 1.8 support:
  class EncodingError < StandardError; end unless defined?(EncodingError)
  # Raised when we cannot ensure a string is valid UTF-8
  class UTF8CoercionError < EncodingError; end

  # Our known source encodings, in order of preference:
  AUTO_ENCODINGS = %w( UTF-8 UTF-16 Windows-1252 )
  # Does the current Ruby support encodings?
  ENCODING_AWARE = ''.respond_to?(:valid_encoding?)
  # How should unmappable characters be escaped, when forcing encoding?
  REPLACEMENT_SCHEME = lambda { |char| '0x' + char.ord.to_s(16).rjust(2, '0') }

  # Returns true if the current Ruby supports string encodings.
  # TODO: Code out of existance once we're past Ruby 1.8.7
  def encoding_aware?
    ENCODING_AWARE
  end

  # Returns a new string with valid UTF-8 encoding,
  # or raises an exception if encoding fails.
  def ensure_utf8(string, source_encoding = nil)
    ensure_utf8!(string.dup, source_encoding)
  end

  # Attempts to encode `string` to UTF-8, in place.
  # Returns `string`, or raises an exception.
  def ensure_utf8!(string, source_encoding = nil)
    return string unless encoding_aware?

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
    return string unless encoding_aware?

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
