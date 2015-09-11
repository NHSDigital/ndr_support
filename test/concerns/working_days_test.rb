require 'test_helper'

# This tests our WorkingDays Time/Date/DateTime extension
class WorkingDaysTest < Minitest::Test
  def setup
    @normal_date      = Date.parse('2015-02-02')          # Monday 2nd Feb 2015
    @normal_time      = Time.parse('2015-02-02 2pm')      # Monday 2nd Feb 2015
    @normal_date_time = DateTime.parse('2015-02-02 11am') # Monday 2nd Feb 2015

    @easter_date      = Date.parse('2015-04-06')          # Easter Monday, 2015
    @easter_time      = Time.parse('2015-04-06 2pm')      # Easter Monday, 2015
    @easter_date_time = DateTime.parse('2015-04-06 11am') # Easter Monday, 2015
  end

  test 'should identify weekdays' do
    assert Date.parse('2015-12-25').weekday?
    assert Time.parse('2015-12-25 3pm').weekday?
    assert DateTime.parse('2015-12-25 3pm').weekday?

    refute Date.parse('2015-12-26').weekday?
    refute Time.parse('2015-12-26 3pm').weekday?
    refute DateTime.parse('2015-12-26 3pm').weekday?
  end

  test 'should identify bank holidays' do
    assert Date.parse('2015-12-25').public_holiday?
    assert Time.parse('2015-12-25 3pm').public_holiday?
    assert DateTime.parse('2015-12-25 3pm').public_holiday?

    # Boxing Day 2015 is a Saturday; the bank holiday a
    # substitute day, on the following Monday:
    refute Date.parse('2015-12-26').public_holiday?
    refute Time.parse('2015-12-26 3pm').public_holiday?
    refute DateTime.parse('2015-12-26 3pm').public_holiday?

    assert Date.parse('2015-12-28').public_holiday?
    assert Time.parse('2015-12-28 3pm').public_holiday?
    assert DateTime.parse('2015-12-28 3pm').public_holiday?
  end

  test 'should allow comparison of Time and DateTime' do
    @normal_time.working_days_until(@normal_date_time)
    @normal_date_time.working_days_until(@normal_time)
  end

  test 'should allow comparison of DateTime and Date' do
    @normal_date_time.working_days_until(@normal_date)
    @normal_date.working_days_until(@normal_date_time)
  end

  test 'should be zero working days between same normal day' do
    assert_equal 0, @normal_date.working_days_until(@normal_date)
    assert_equal 0, @normal_time.working_days_until(@normal_time + 6.hours)
    assert_equal 0, @normal_date_time.working_days_until(@normal_date_time + 6.hours)
  end

  test 'Monday -> Friday should be 4 working days' do
    assert_equal 4, @normal_date.working_days_until(@normal_date + 4.days)
    assert_equal 4, @normal_time.working_days_until(@normal_time + 4.days)
    assert_equal 4, @normal_date_time.working_days_until(@normal_date_time + 4.days)
  end

  test 'Friday <- Monday should be -4 working days' do
    assert_equal(-4, (@normal_date + 4.days).working_days_until(@normal_date))
    assert_equal(-4, (@normal_time + 4.days).working_days_until(@normal_time))
    assert_equal(-4, (@normal_date_time + 4.days).working_days_until(@normal_date_time))
  end

  test 'Saturday -> Sunday should be 0 working days' do
    assert_equal 0, (@normal_date - 2.days).working_days_until(@normal_date - 1.day)
    assert_equal 0, (@normal_time - 2.days).working_days_until(@normal_time - 1.day)
    assert_equal 0, (@normal_date_time - 2.days).working_days_until(@normal_date_time - 1.day)
  end

  test 'Sunday <- Saturday should be 0 working days' do
    assert_equal 0, (@normal_date - 1.day).working_days_until(@normal_date - 2.days)
    assert_equal 0, (@normal_time - 1.day).working_days_until(@normal_time - 2.days)
    assert_equal 0, (@normal_date_time - 1.day).working_days_until(@normal_date_time - 2.days)
  end

  test 'Monday -> next Monday should be 5 working days' do
    assert_equal 5, @normal_date.working_days_until(@normal_date + 7.days)
    assert_equal 5, @normal_time.working_days_until(@normal_time + 7.days)
    assert_equal 5, @normal_date_time.working_days_until(@normal_date_time + 7.days)
  end

  test 'Monday -> Easter Monday should be 3 working days' do
    assert_equal 3, (@easter_date - 7.days).working_days_until(@easter_date)
    assert_equal 3, (@easter_time - 7.days).working_days_until(@easter_time)
    assert_equal 3, (@easter_date_time - 7.days).working_days_until(@easter_date_time)
  end

  test 'Tuesday -> Tuesday over Easter should be 3 working days' do
    assert_equal 3, (@easter_date - 6.days).working_days_until(@easter_date + 1.day)
    assert_equal 3, (@easter_time - 6.days).working_days_until(@easter_time + 1.day)
    assert_equal 3, (@easter_date_time - 6.days).working_days_until(@easter_date_time + 1.day)
  end

  test 'Good Friday -> Friday should be 4 working days' do
    assert_equal 4, (@easter_date - 3.days).working_days_until(@easter_date + 4.day)
    assert_equal 4, (@easter_time - 3.days).working_days_until(@easter_time + 4.day)
    assert_equal 4, (@easter_date_time - 3.days).working_days_until(@easter_date_time + 4.day)
  end

  test 'Friday -> Monday should be 1 working day' do
    assert_equal 1, (@normal_date - 3.days).working_days_until(@normal_date)
    assert_equal 1, (@normal_time - 3.days).working_days_until(@normal_time)
    assert_equal 1, (@normal_date_time - 3.days).working_days_until(@normal_date_time)
  end

  test 'A year of week days' do
    assert_equal 261, @normal_date.weekdays_until(@normal_date + 1.year)
    assert_equal 261, @normal_time.weekdays_until(@normal_time + 1.year)
    assert_equal 261, @normal_date_time.weekdays_until(@normal_date_time + 1.year)
  end

  test 'A year of working days' do
    assert_equal 253, @normal_date.working_days_until(@normal_date + 1.year)
    assert_equal 253, @normal_time.working_days_until(@normal_time + 1.year)
    assert_equal 253, @normal_date_time.working_days_until(@normal_date_time + 1.year)
  end
end
