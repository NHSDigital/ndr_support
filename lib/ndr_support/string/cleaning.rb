require 'active_support/core_ext/string/filters'
require 'ndr_support/string/clean_methodable'

# Extends String clean with various methods of cleaning strings
# zand polishing them
class String
  include CleanMethodable

  INVALID_CONTROL_CHARS = /[\x00-\x08\x0b-\x0c\x0e-\x1f]/

  POSTCODE_REGEXP = /
    ^(
      [A-Z][0-9]           |
      [A-Z][0-9][0-9]      |
      [A-Z][0-9][A-Z]      |
      [A-Z][A-Z][0-9]      |
      NPT                  |
      [A-Z][A-Z][0-9][0-9] |
      [A-Z][A-Z][0-9][A-Z]
    )
    [0-9][A-Z][A-Z]
  $/x

  # Used for comparing addresses
  def squash
    upcase.delete('^A-Z0-9')
  end

  # Show postcode in various formats.
  # Parameter "option" can be :user, :compact, :db
  def postcodeize(option = :user)
    nspce = gsub(/[[:space:]]/, '').upcase
    return self unless nspce.blank? || POSTCODE_REGEXP =~ nspce # Don't change old-style or malformed postcodes

    case option
    when :compact
      nspce
    when :db
      case nspce.length
      when 5 then nspce.insert(-4, '  ')
      when 6 then nspce.insert(-4, ' ')
      else nspce
      end
    else # anything else, including :user --> friendly format
      nspce.length < 5 ? nspce : nspce.insert(-4, ' ')
    end
  end

  def strip_xml_unsafe_characters
    gsub(String::INVALID_CONTROL_CHARS, '')
  end

  def xml_unsafe?
    self =~ String::INVALID_CONTROL_CHARS
  end

  protected

  def split_on_separators(regexp = / |,|;/)
    split(regexp)
  end
end
