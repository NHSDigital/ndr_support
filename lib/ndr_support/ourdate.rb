require 'active_record'
require 'active_support/time'
require 'ndr_support/ourdate/build_datetime'
require 'ndr_support/date_and_time_extensions'
require 'ndr_support/daterange'

# Convert a string into a single date
# (helped by String.thedate)
class Ourdate
  attr_reader :thedate

  # We need a daylight saving time safe was of defining the date today.
  def self.today
    current_time = Time.now
    #--
    # TODO: Use Ourdate.build_datetime everywhere below:
    #++
    if ActiveRecord::Base.default_timezone == :local
      build_datetime(current_time.year, current_time.month, current_time.day)
    else
      #--
      # Only supports fake GMT time -- needs improvement
      # Maybe use Time.zone.local or Time.local_time(year, month, day)
      #++
      Time.gm(current_time.year, current_time.month, current_time.day, 0, 0, 0, 0).to_datetime
    end
  end

  def initialize(x = nil)
    if x.is_a?(Date)
      @thedate = x
    elsif x.is_a?(Time)
      @thedate = x.to_datetime
    elsif x.is_a?(String)
      self.source = x
    else
      @thedate = nil
    end
  end

  def to_s
    @thedate ? @thedate.to_date.to_formatted_s(:ui) : ''
  end

  def empty?
    # An unspecified date will be empty. A valid date will not.
    @thedate.nil?
  end

  def source=(s)
    dr = Daterange.new(s)
    if dr.date1 == dr.date2
      @thedate = dr.date1
    else
      @thedate = nil
    end
  end

  # Compute date difference in years (e.g. patient age), as an integer
  # For a positive result, the later date should be the first argument.
  # Leap days are treated as for age calculations.
  def self.date_difference_in_years(date2, date1)
    (date2.strftime('%Y%m%d').sub(/0229$/, '0228').to_i -
     date1.strftime('%Y%m%d').sub(/0229$/, '0228').to_i) / 10_000
  end

  private :source=
end
