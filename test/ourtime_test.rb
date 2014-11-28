require 'test_helper'

class OurtimeTest < ActiveSupport::TestCase
  def test_Ourtime
    # Creating an Ourtime from a local-format String (with seconds)
    ot = Ourtime.new('01.02.1993 04:05:06')
    assert_equal "1993-02-01 04:05:06", ot.thetime.strftime("%Y-%m-%d %H:%M:%S")
    assert_kind_of Time, ot.thetime
    # Creating an Ourtime from a Time
    ot = Ourtime.new(Time.mktime(1993, 2, 1, 4, 5))
    assert_equal '01.02.1993 04:05', ot.to_s

    assert Ourtime.new.blank?  # delegates to empty?
    # Parsing an ISO datetime
    ot = Ourtime.new("1993-04-05 06:07:08")
    assert_equal "1993-04-05 06:07:08", ot.thetime.strftime("%Y-%m-%d %H:%M:%S")
  end
end