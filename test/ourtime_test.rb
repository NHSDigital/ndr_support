require 'test_helper'

# This tests our Ourtime class
class OurtimeTest < Minitest::Test
  def test_initialize_with_local_format_string_gmt
    # Creating an Ourtime from a local-format String (with seconds)
    ot = Ourtime.new('01.02.1993 04:05:06')
    assert_equal '1993-02-01 04:05:06', ot.thetime.strftime('%Y-%m-%d %H:%M:%S')
    assert_kind_of Time, ot.thetime
    assert_equal 'GMT', ot.thetime.zone
  end

  def test_initialize_with_local_format_string_bst
    # Creating an Ourtime from a local-format String (with seconds)
    ot = Ourtime.new('01.08.1993 04:05:06')
    assert_equal '1993-08-01 04:05:06', ot.thetime.strftime('%Y-%m-%d %H:%M:%S')
    assert_kind_of Time, ot.thetime
    assert_equal 'BST', ot.thetime.zone
  end

  def test_initialize_with_time
    # Creating an Ourtime from a Time
    ot = Ourtime.new(Time.mktime(1993, 2, 1, 4, 5))
    assert_equal '01.02.1993 04:05', ot.to_s
    assert_equal 'GMT', ot.thetime.zone
  end

  def test_initialize_with_no_parameters
    assert Ourtime.new.blank?  # delegates to empty?
  end

  def test_initialize_with_iso_string_bst
    # Parsing an ISO datetime
    ot = Ourtime.new('1993-05-05 06:07:08')
    assert_equal '1993-05-05 06:07:08', ot.thetime.strftime('%Y-%m-%d %H:%M:%S')
    assert_equal 'BST', ot.thetime.zone
  end

  def test_initialize_with_iso_string_gmt
    # Parsing an ISO datetime
    ot = Ourtime.new('1993-01-05 06:07:08')
    assert_equal '1993-01-05 06:07:08', ot.thetime.strftime('%Y-%m-%d %H:%M:%S')
    assert_equal 'GMT', ot.thetime.zone
  end
end
