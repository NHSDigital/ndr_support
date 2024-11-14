require 'test_helper'

# This tests our various date and time class extensions
# Note that these will probably all need to be changed in a major bump of ndr_support
# once we've moved everything to Rails 7.
class DateAndTimeExtensionsTest < Minitest::Test
  def test_date_to_s
    d = Date.new(2000, 2, 1)
    if d.respond_to?(:to_default_s) # Only defined on Rails <= 7.1
      assert_equal '2000-02-01', d.to_default_s, 'Rails 7 default to_s'
    else
      assert_equal '2000-02-01', d.orig_to_s, 'Rails 7 default to_s (via our shim)'
    end
    assert_equal '01.02.2000', d.to_formatted_s(:default), 'Rails 6 default to_s'
    assert_equal d.to_formatted_s(:default), d.to_s,
                 'We plan to change default to_s behaviour in a major version bump'
  end

  def test_datetime_to_s
    bst_datetime = DateTime.new(2014, 4, 1, 0, 0, 0, '+1')
    if bst_datetime.respond_to?(:to_default_s) # Only defined on Rails <= 7.1
      assert_equal '2014-04-01T00:00:00+01:00', bst_datetime.to_default_s, 'Rails 7 default to_s'
    else
      assert_equal '2014-04-01T00:00:00+01:00', bst_datetime.orig_to_s, 'Rails 7 default to_s (via our shim)'
    end
    assert_equal '01.04.2014', bst_datetime.to_formatted_s(:default), 'Rails 6 default to_s'
    assert_equal bst_datetime.to_formatted_s(:default), bst_datetime.to_s,
                 'We plan to change default to_s behaviour in a major version bump'

    gmt_datetime = DateTime.new(2014, 3, 1, 0, 0, 0, '+0')
    if gmt_datetime.respond_to?(:to_default_s) # Only defined on Rails <= 7.1
      assert_equal '2014-03-01T00:00:00+00:00', gmt_datetime.to_default_s, 'Rails 7 default to_s'
    else
      assert_equal '2014-03-01T00:00:00+00:00', gmt_datetime.orig_to_s, 'Rails 7 default to_s (via our shim)'
    end
    assert_equal '01.03.2014', gmt_datetime.to_formatted_s(:default), 'Rails 6 default to_s'
    assert_equal gmt_datetime.to_formatted_s(:default), gmt_datetime.to_s,
                 'We plan to change default to_s behaviour in a major version bump'

    datetime_with_hhmmss = DateTime.new(2014, 4, 1, 12, 35, 11, '+0')
    if datetime_with_hhmmss.respond_to?(:to_default_s) # Only defined on Rails <= 7.1
      assert_equal '2014-04-01T12:35:11+00:00', datetime_with_hhmmss.to_default_s,
                   'Rails 7 default to_s'
    else
      assert_equal '2014-04-01T12:35:11+00:00', datetime_with_hhmmss.orig_to_s,
                   'Rails 7 default to_s (via our shim)'
    end
    assert_equal '01.04.2014 12:35', datetime_with_hhmmss.to_formatted_s(:default),
                 'Rails 6 default to_s'
    assert_equal datetime_with_hhmmss.to_formatted_s(:default), datetime_with_hhmmss.to_s,
                 'We plan to change default to_s behaviour in a major version bump'
  end

  def test_time_to_s
    time = Time.new(2014, 4, 1, 12, 35, 11.5, '+01:00')
    if time.respond_to?(:to_default_s) # Only defined on Rails <= 7.1
      assert_equal '2014-04-01 12:35:11 +0100', time.to_default_s, 'Rails 7 default to_s'
    else
      assert_equal '2014-04-01 12:35:11 +0100', time.orig_to_s, 'Rails 7 default to_s (via our shim)'
    end
    assert_equal '01.04.2014 12:35', time.to_formatted_s(:default), 'Rails 6 default to_s'
    assert_equal time.to_formatted_s(:default), time.to_s,
                 'We plan to change default to_s behaviour in a major version bump'
  end

  def test_time_with_zone_to_s
    time_with_zone = Time.find_zone('Europe/London').local(2014, 4, 1, 12, 35, 11.5)
    assert_equal 'BST', time_with_zone.zone
    # Without ndr_support extensions, we'd expect "2014-04-01 12:35:11 +0100"
    # but we have to trick the database into assuming all times are UTC to retain local time
    if time_with_zone.respond_to?(:to_default_s) # Only defined on Rails <= 7.1
      assert_equal '2014-04-01 12:35:11 UTC', time_with_zone.to_default_s,
                   'Rails 7 default to_s with our date and time formatting'
    else
      assert_equal '2014-04-01 12:35:11 +0100', time_with_zone.orig_to_s,
                   'Rails 7 default to_s with our date and time formatting (via our shim)'
    end
    assert_equal '01.04.2014 12:35', time_with_zone.to_formatted_s(:default), 'Rails 6 default to_s'
    assert_equal time_with_zone.to_formatted_s(:default), time_with_zone.to_s,
                 'We plan to change default to_s behaviour in a major version bump'
  end
end
