require 'active_support/time'

# This module contains logic for #working_days_until, #weekday?, and #public_holiday?.
module WorkingDays
  WEEK_DAYS = 1..5
  HOLIDAYS  = [ # Sourced from https://www.gov.uk/bank-holidays
    # 2012
    '2012-01-02', # Monday    - New Year's Day (substitute day)
    '2012-04-06', # Friday    - Good Friday
    '2012-04-09', # Monday    - Easter Monday
    '2012-05-07', # Monday    - Early May bank holiday
    '2012-06-04', # Monday    - Spring bank holiday (substitute day)
    '2012-06-05', # Tuesday   - Queen's Diamond Jubilee (extra bank holiday)
    '2012-08-27', # Monday    - Summer bank holiday
    '2012-12-25', # Tuesday   - Christmas Day
    '2012-12-26', # Wednesday - Boxing Day
    # 2013
    '2013-01-01', # Tuesday   - New Year's Day
    '2013-03-29', # Friday    - Good Friday
    '2013-04-01', # Monday    - Easter Monday
    '2013-05-06', # Monday    - Early May bank holiday
    '2013-05-27', # Monday    - Spring bank holiday
    '2013-08-26', # Monday    - Summer bank holiday
    '2013-12-25', # Wednesday - Christmas Day
    '2013-12-26', # Thursday  - Boxing Day
    # 2014
    '2014-01-01', # Wednesday - New Year's Day
    '2014-04-18', # Friday    - Good Friday
    '2014-04-21', # Monday    - Easter Monday
    '2014-05-05', # Monday    - Early May bank holiday
    '2014-05-26', # Monday    - Spring bank holiday
    '2014-08-25', # Monday    - Summer bank holiday
    '2014-12-25', # Thursday  - Christmas Day
    '2014-12-26', # Friday    - Boxing Day
    # 2015
    '2015-01-01', # Thursday  - New Year's Day
    '2015-04-03', # Friday    - Good Friday
    '2015-04-06', # Monday    - Easter Monday
    '2015-05-04', # Monday    - Early May bank holiday
    '2015-05-25', # Monday    - Spring bank holiday
    '2015-08-31', # Monday    - Summer bank holiday
    '2015-12-25', # Friday    - Christmas Day
    '2015-12-28', # Monday    - Boxing Day (substitute day)
    # 2016
    '2016-01-01', # Friday    - New Year's Day
    '2016-03-25', # Friday    - Good Friday
    '2016-03-28', # Monday    - Easter Monday
    '2016-05-02', # Monday    - Early May bank holiday
    '2016-05-30', # Monday    - Spring bank holiday
    '2016-08-29', # Monday    - Summer bank holiday
    '2016-12-26', # Monday    - Boxing Day
    '2016-12-27', # Tuesday   - Christmas Day (substitute day)
  ].map { |str| Date.parse(str) }

  # How many complete working days there are until the given
  # `other`. Returns negative number if `other` is earlier.
  def working_days_until(other)
    return -other.working_days_until(self) if other < self

    whole_days_to(other).count do |day|
      day.weekday? && !day.public_holiday?
    end
  end

  # How many complete weekdays there are until the given
  # `other`. Returns negative number if `other` is earlier.
  def weekdays_until(other)
    return -other.weekdays_until(self) if other < self
    whole_days_to(other).count(&:weekday?)
  end

  # Is this a weekday?
  def weekday?
    WEEK_DAYS.include? wday
  end

  # Is this a public holiday (in England / Wales)?
  def public_holiday?
    HOLIDAYS.include? to_date
  end

  private

  def whole_days_to(other)
    [self].tap do |days|
      loop do
        next_day  = days.last + 1.day
        next_day <= other ? days.push(next_day) : break
      end

      days.shift # Drop `self` off the front
    end
  end
end
