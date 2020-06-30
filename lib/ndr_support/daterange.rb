require 'active_support/core_ext/enumerable'
require 'active_support/time'
require 'ndr_support/integer/julian_date_conversions'

# Our "vague date" class, which can represent a single date or a date range.
class Daterange
  attr_reader :date1, :date2, :source

  OKYEARS = 1880..2030

  def self.extract(dates_string)
    dates_string.to_s.split(',').map { |str| new(str) }
  end

  def self.merge(dates_string)
    ranges = extract(dates_string)
    new(ranges.map(&:date1).compact.min, ranges.map(&:date2).compact.max)
  end

  def initialize(x1 = nil, x2 = nil)
    x1 = x1.to_datetime if x1.is_a?(Date) || x1.is_a?(Time)
    x2 = x2.to_datetime if x2.is_a?(Date) || x2.is_a?(Time)

    if x1.is_a?(DateTime) && x2.is_a?(DateTime)
      @date1 = [x1, x2].min
      @date2 = [x1, x2].max
      @source = nil
    elsif x1.is_a?(Daterange) && x2.nil?  # Patient model line 645
      @date1 = x1.date1
      @date2 = x1.date2
      @source = x1.source
    elsif x1.is_a?(DateTime) && x2.nil?
      @date1 = x1
      @date2 = x1
      @source = nil
    elsif x1.is_a?(String) && x2.nil?
      self.source = (x1)
    else
      @date1 = nil
      @date2 = nil
      @source = nil
    end
    self.freeze
  end

  # If we have a valid date range, return a string representation of it
  # TODO: possibly add support for to_s(format) e.g. to_s(:short)
  def to_s
    return '' unless @date1 && @date2
    if @date1 == @date2 # single date
      tidy_string_if_midnight(@date1)
    elsif tidy_string_if_midnight(@date1) == tidy_string_if_midnight(@date2.at_beginning_of_year) &&
          tidy_string_if_midnight(@date2) == tidy_string_if_midnight(@date1.at_end_of_year.at_beginning_of_day) # whole year
      @date1.strftime('%Y')
    elsif tidy_string_if_midnight(@date1) == tidy_string_if_midnight(@date2.at_beginning_of_month) &&
          tidy_string_if_midnight(@date2) == tidy_string_if_midnight(@date1.at_end_of_month.at_beginning_of_day) # whole month
      @date1.strftime('%m.%Y')
    else # range
      tidy_string_if_midnight(@date1) + ' to ' + tidy_string_if_midnight(@date2)
    end
  end

  # used in Address model
  # to_iso output must be SQL safe for security reasons
  def to_iso
    date1.is_a?(DateTime) ? date1.to_iso : ''
  end

  # A long string representation of the date or range
  def verbose
    return 'Bad date(s)' unless @date1 && @date2
    if @date1 == @date2 # single date
      _verbose(@date1)
    else # range
      'The period ' + _verbose(@date1) + ' to ' + _verbose(@date2) +
        ' inclusive (' + (@date2 - @date1 + 1).to_i.to_s + ' days)'
    end
  end

  def date1=(d)
    if @source
      @source += ' [d1 modified]'
    else
      @source = '[d1 modified]'
    end
    @date1 = d
  end

  def date2=(d)
    if @source
      @source += ' [d2 modified]'
    else
      @source = '[d2 modified]'
    end
    @date2 = d
  end

  def <=>(other)
    self.date1 <=> other.date1
  end

  def ==(other)
    date1 == other.date1 && date2 == other.date2
  rescue NoMethodError # Comparing to things that don't work like Dateranges, e.g. nil, integer
    false
  end

  def intersects?(other)
    !(self.empty? || other.empty?) && self.date1 <= other.date2 && self.date2 >= other.date1
  end

  def empty?
    # An unspecified date will be empty. A valid or invalid date will not.
    @date1.nil? && @source.blank?
  end

  def exact?
    @date1 == @date2
  end

  private

  def _verbose(date)
    date.strftime('%d %B %Y')
  end

  def tidy_string_if_midnight(datetime)
    if datetime.hour == 0 && datetime.min == 0 && datetime.sec == 0
      # it's midnight
      datetime.to_date.to_s(:ui)
    else
      return datetime.to_time.to_s(:ui)
    end
  end

  # Update our attribute values using a string representation of the date(s).
  # +s+ consists of one or more dates separated with spaces.
  # Each date can be in various formats, e.g. d/m/yyyy, ddmmyyyy, yyyy-mm-dd, dd-mon-yyyy
  # Each date can omit days or months, e.g. yyyy, dd/yyyy, yyyy-mm, mon-yyyy
  def source=(s)
    @source = s
    ss = s.upcase.sub(/TO/, ' ') # accept default _to_s format
    if ss =~ /[^\w0-9\-\/\. ]/i # only allow letters, digits, hyphen, slash, dot, space
      @date1 = @date2 = nil
    else
      da = [] # temporary array of arrays of dates
      ss.split(' ').each do |vaguedate|
        da << str_to_date_array(vaguedate)
      end
      da.flatten!
      if da.include?(nil)
        @date1 = @date2 =  nil
      else
        da.sort!
        @date1, @date2 = da.first, da.last
      end
    end
  end

  # Take a string representation of a single date (which may be incomplete,
  # e.g year only or year/month only) and return an array of two dates,
  # being the earliest and latest that fit the partial date.
  def str_to_date_array(ds)
    parts = date_string_parts(ds)
    return if parts.nil? || OKYEARS.exclude?(parts[0])

    case parts.length
    when 1 # just a year
      j1 = Date.new(parts[0], 1, 1).jd
      j2 = Date.new(parts[0], 12, 31).jd
    when 2 # year and month
      j1 = Date.new(parts[0], parts[1], 1).jd
      j2 = Date.new(parts[0], parts[1], -1).jd
    when 3 # full date
      j1 = j2 = Date.new(parts[0], parts[1], parts[2]).jd
    end

    [j1.jd_to_datetime, j2.jd_to_datetime]
  rescue
    nil
  end

  # Take a string representation of a single date (which may be incomplete,
  # e.g year only or year/month only) and return an array of 1..3 integers
  # representing the year, month and day
  def date_string_parts(ds)
    if ds =~ /\A(\d{1,2}[\/\.\-])?\w{3}[\/\.\-]\d{4}\z/i # dd[-/.]mon[-/.]yyyy or mon[-/.]yyyy
      result = handle_three_char_months(ds)
    elsif ds =~ /([\/\.\-])/ # find a slash or dot or hyphen
      delimiter = $1
      result = ds.split(delimiter)
    elsif ds.length == 8 # ddmmyyyy
      result = [ds[0..1], ds[2..3], ds[4..7]]
    elsif ds.length == 6 # mmyyyy
      result = [ds[0..1], ds[2..5]]
    elsif ds.length == 4 # yyyy
      result = [ds]
    else
      result = []
    end
    return nil unless (1..3) === result.length
    result.reverse! unless delimiter == '-' # change to YMD if not ISO format
    result.collect(&:to_i)
  end

  def handle_three_char_months(datestring)
    delimiter  = datestring.match(%r{[\/\.\-]})[0]
    components = datestring.split(delimiter)

    if datestring =~ /\A\d{1,2}#{delimiter}\w{3}#{delimiter}\d{4}\z/i
      month = abbreviated_month_index_for(components[1])
      month.nil? ? [] : [components.first, month, components.last]
    elsif datestring =~ /\A\w{3}#{delimiter}\d{4}\z/i
      month = abbreviated_month_index_for(components.first)
      month.nil? ? [] : [month, components.last]
    end
  end

  def abbreviated_month_index_for(string)
    Date::ABBR_MONTHNAMES.index(string.capitalize)
  end
end
