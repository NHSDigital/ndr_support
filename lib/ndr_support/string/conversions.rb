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
    def self.parsedate(str, comp=false)
      Date._parse(str, comp).
        values_at(:year, :mon, :mday, :hour, :min, :sec, :zone, :wday)
    end
  end
end

class String
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

  # Try to convert the string value into a date.
  # If given a pattern, use it to parse date, otherwise use default setting to parse it
  def to_date(pattern = nil)
    return ''  if empty? # TODO: check if this is used... :/
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
      elsif 8 == length && self !~ /\d{8}/
        # dd/mm/yy, rather than yyyymmdd
        year, day = day, year
        year += 100 if year <= Ourdate.today.year % 100
        year += 1900
      elsif 9 == length
        # dd/mmm/yy, rare case.
        year += 100 if year <= Ourdate.today.year % 100
        year += 1900
      end

      Ourdate.build_datetime(year, month, day)
    end
  end

  # Try to convert the string value into boolean
  def to_boolean
    # SECURE: BNS 2012-10-09: But may behave oddly for multi-line input
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.nil? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end
