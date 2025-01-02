require 'active_support/time'

# This module contains logic for #working_days_until, #weekday?, and #public_holiday?.
module WorkingDays
  WEEK_DAYS = 1..5
  
  # TODO: could we use https://github.com/alphagov/gds-api-adapters ?
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
    # 2017
    '2017-01-02', # Monday    - New Year's Day
    '2017-04-14', # Friday    - Good Friday
    '2017-04-17', # Monday    - Easter Monday
    '2017-05-01', # Monday    - Early May bank holiday
    '2017-05-29', # Monday    - Spring bank holiday
    '2017-08-28', # Monday    - Summer bank holiday
    '2017-12-25', # Monday    - Christmas Day
    '2017-12-26', # Tuesday   - Boxing Day
    # 2018
    '2018-01-01', # Monday    - New Year's Day
    '2018-03-30', # Friday    - Good Friday
    '2018-04-02', # Monday    - Easter Monday
    '2018-05-07', # Monday    - Early May bank holiday
    '2018-05-28', # Monday    - Spring bank holiday
    '2018-08-27', # Monday    - Summer bank holiday
    '2018-12-25', # Tuesday   - Christmas Day
    '2018-12-26', # Wednesday - Boxing Day
    # 2019
    '2019-01-01', # Tuesday   - New Year's Day
    '2019-04-19', # Friday    - Good Friday
    '2019-04-22', # Monday    - Easter Monday
    '2019-05-06', # Monday    - Early May bank holiday
    '2019-05-27', # Monday    - Spring bank holiday
    '2019-08-26', # Monday    - Summer bank holiday
    '2019-12-25', # Wednesday - Christmas Day
    '2019-12-26', # Thursday  - Boxing Day
    # 2020
    '2020-01-01', # Wednesday - New Year's Day
    '2020-04-10', # Friday    - Good Friday
    '2020-04-13', # Monday    - Easter Monday
    '2020-05-08', # Friday    - Early May bank holiday (moved from Monday)
    '2020-05-25', # Monday    - Spring bank holiday
    '2020-08-31', # Monday    - Summer bank holiday
    '2020-12-25', # Friday    - Christmas Day
    '2020-12-28', # Monday    - Boxing Day (substitute day)
    # 2021
    '2021-01-01', # Friday - New Year’s Day
    '2021-04-02', # Friday - Good Friday
    '2021-04-05', # Monday - Easter Monday
    '2021-05-03', # Monday - Early May bank holiday
    '2021-05-31', # Monday - Spring bank holiday
    '2021-08-30', # Monday - Summer bank holiday
    '2021-12-27', # Monday - Christmas Day
    '2021-12-28', # Tuesday - Boxing Day
    # 2022
    '2022-01-03', # Monday   - New Year’s Day (substitute day)
    '2022-04-15', # Friday   - Good Friday
    '2022-04-18', # Monday   - Easter Monday
    '2022-05-02', # Monday   - Early May bank holiday
    '2022-06-02', # Thursday - Spring bank holiday
    '2022-06-03', # Friday   - Platinum Jubilee bank holiday
    '2022-08-29', # Monday   - Summer bank holiday
    '2022-09-19', # Monday   - Bank Holiday for the State Funeral of Queen Elizabeth II
    '2022-12-26', # Monday   - Boxing Day
    '2022-12-27', # Tuesday  - Christmas Day (substitute day)
    # 2023
    '2023-01-02', # Monday   - New Year’s Day (substitute day)
    '2023-04-07', # Friday   - Good Friday
    '2023-04-10', # Monday   - Easter Monday
    '2023-05-01', # Monday   - Early May bank holiday
    '2023-05-08', # Monday    - Bank holiday for the coronation of King Charles III
    '2023-05-29', # Monday   - Spring bank holiday
    '2023-08-28', # Monday   - Summer bank holiday
    '2023-12-25', # Monday   - Christmas Day
    '2023-12-26', # Tuesday  - Boxing Day
    # 2024
    '2024-01-01', # Monday    - New Year’s Day
    '2024-03-29', # Friday    - Good Friday
    '2024-04-01', # Monday    - Easter Monday
    '2024-05-06', # Monday    - Early May bank holiday
    '2024-05-27', # Monday    - Spring bank holiday
    '2024-08-26', # Monday    - Summer bank holiday
    '2024-12-25', # Wednesday - Christmas Day
    '2024-12-26', # Thursday  - Boxing Day
    # 2025
    '2025-01-01', # Wednesday - New Year’s Day
    '2025-04-18', # Friday    - Good Friday
    '2025-04-21', # Monday    - Easter Monday
    '2025-05-05', # Monday    - Early May bank holiday
    '2025-05-26', # Monday    - Spring bank holiday
    '2025-08-25', # Monday    - Summer bank holiday
    '2025-12-25', # Thursday  - Christmas Day
    '2025-12-26', # Friday    - Boxing Day
    # 2026
    '2026-01-01', # Thursday  - New Year’s Day
    '2026-04-03', # Friday    - Good Friday
    '2026-04-06', # Monday    - Easter Monday
    '2026-05-04', # Monday    - Early May bank holiday
    '2026-05-25', # Monday    - Spring bank holiday
    '2026-08-31', # Monday    - Summer bank holiday
    '2026-12-25', # Friday    - Christmas Day
    '2026-12-28', # Monday    - Boxing Day
    # 2027
    '2027-01-01', # Friday    - New Year’s Day
    '2027-03-26', # Friday    - Good Friday
    '2027-03-29', # Monday    - Easter Monday
    '2027-05-03', # Monday    - Early May bank holiday
    '2027-05-31', # Monday    - Spring bank holiday
    '2027-08-30', # Monday    - Summer bank holiday
    '2027-12-27', # Monday    - Christmas Day
    '2027-12-28', # Tuesday   - Boxing Day
  ].map { |str| Date.parse(str) }

  def self.check_lookup
    return true if HOLIDAYS.max >= 1.year.from_now

    warn "NdrSupport's WorkingDays extension has under a year of future data. Check for updates?"
    false
  end

  # How many complete working days there are until the given
  # `other`. Returns negative number if `other` is earlier.
  def working_days_until(other)
    return -other.working_days_until(self) if other < self

    count_whole_days_to(other) do |day|
      day.weekday? && !day.public_holiday?
    end
  end

  # How many complete weekdays there are until the given
  # `other`. Returns negative number if `other` is earlier.
  def weekdays_until(other)
    return -other.weekdays_until(self) if other < self
    count_whole_days_to(other, &:weekday?)
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

  def count_whole_days_to(other, &block)
    day = self + 1.day
    count = 0

    while day <= other
      count += 1 if block.call(day)
      day += 1.day
    end

    count
  end
end
