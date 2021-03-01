# encoding: utf-8
require 'active_support/core_ext/string/conversions'
require 'ndr_support/daterange'
require 'ndr_support/ourdate'
require 'ndr_support/ourtime'

# Forward-port ParseDate to Ruby 1.9.x and beyond.
# We only use this in String#to_date, but keep the logic
# encapsulated for testing purposes - the behaviour of
# Date._parse has been known to change.
unless defined?(::ParseDate)
  class ParseDate
    def self.parsedate(str, comp = false)
      Date._parse(str, comp).
        values_at(:year, :mon, :mday, :hour, :min, :sec, :zone, :wday)
    end
  end
end

class String
  SOUNDEX_CHARS = 'BPFVCSKGJQXZDTLMNR'
  SOUNDEX_NUMS  = '111122222222334556'
  SOUNDEX_CHARS_EX = '^' + SOUNDEX_CHARS
  SOUNDEX_CHARS_DEL = '^A-Z'

  # desc: http://en.wikipedia.org/wiki/Soundex
  def soundex(census = true)
    str = upcase.delete(SOUNDEX_CHARS_DEL).squeeze

    str[0..0] + str[1..-1].
      delete(SOUNDEX_CHARS_EX).
      tr(SOUNDEX_CHARS, SOUNDEX_NUMS)[0..(census ? 2 : -1)].
      squeeze[0..(census ? 2 : -1)].
      ljust(3, '0') rescue ''
  end

  def sounds_like(other)
    soundex == other.soundex
  end

  def date1
    Daterange.new(self).date1
  end

  def date2
    Daterange.new(self).date2
  end

  def thedate
    Ourdate.new(self).thedate
  end

  def thetime
    Ourtime.new(self).thetime
  end

  # Convert "SMITH JD" into "Smith JD"
  def surname_and_initials
    a = split
    initials = a.pop
    a.collect(&:capitalize).join(' ') + ' ' + initials
  end

  # Like titleize but copes with Scottish and Irish names.
  def surnameize
    s = slice(0, 2).upcase
    if s == 'MC' || s == "O'"
      s.titleize + slice(2..-1).titleize
    else
      titleize
    end
  end

  # Show NHS numbers with spaces
  def nhs_numberize
    return self unless length == 10
    self[0..2] + ' ' + self[3..5] + ' ' + self[6..9]
  end

  # truncate a string, with a HTML &hellip; at the end
  def truncate_hellip(n)
    length > n ? slice(0, n - 1) + '&hellip;' : self
  end

  # Try to convert the string value into a date.
  # If given a pattern, use it to parse date, otherwise use default setting to parse it
  redefine_method :to_date do |pattern = nil|
    return nil if blank?

    pattern = '%d%m%Y' if 'ddmmyyyy' == pattern

    if pattern == 'yyyymmdd' || pattern == 'yyyymmdd_ons'
      # Workaround for ONS dates (with missing day / month): revert to old
      # parsing behaviour. (Instead, EDeathRecord should substitute a Daterange)
      # TODO: Move all death parsing to format 'yyyymmdd_ons'
      return nil if self =~ /\A([0-9]{4}00[0-9]{2}|[0-9]{6}00)\Z/
      pattern = '%Y%m%d'
    end

    if self =~ /\A([0-9][0-9]?)[.]([0-9][0-9]?)[.]([0-9][0-9][0-9][0-9])\Z/ # dd.mm.yyyy
      return date1 # Uses Daterange to consistently parse our displayed date format
    end

    if pattern.to_s.include?('%')
      # Use Date.strptime if the pattern contains a percent sign
      parsed_date = DateTime.strptime(self, pattern)
      Ourdate.build_datetime(parsed_date.year, parsed_date.month, parsed_date.day)
    else
      # Use '.' rather than '/' as a separator for more consistent parsing:
      year, month, day, *_ = ParseDate.parsedate(gsub('/', '.'))

      if ['yyyy/dd/mm', 'mm/dd/yyyy'].include?(pattern)
        month, day = day, month
      elsif 8 == length && self =~ /\A\d{2}[^A-Z0-9]\d{2}[^A-Z0-9]\d{2}\z/i
        # dd/mm/yy, rather than yyyymmdd
        year, day = day, year
        year += 100 if year <= Ourdate.today.year % 100
        year += 1900
      elsif 9 == length && self =~ /\A\d{2}[^A-Z0-9][A-Z]{3}[^A-Z0-9]\d{2}\z/i
        # dd/mon/yy, rare case.
        year += 100 if year <= Ourdate.today.year % 100
        year += 1900
      end

      Ourdate.build_datetime(year, month, day)
    end
  end

  alias orig_to_datetime to_datetime

  def to_datetime
    # Default timezone for to_datetime conversion is GMT, not local timezone
    return to_time.to_datetime if ActiveRecord::Base.default_timezone == :local
    orig_to_datetime
  end

  # Try to convert the string value into boolean
  def to_boolean
    # SECURE: BNS 2012-10-09: But may behave oddly for multi-line input
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.nil? || self =~ (/^(false|f|no|n|0)$/i)
    fail ArgumentError, "invalid value for Boolean: \"#{self}\""
  end
end
