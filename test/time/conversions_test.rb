require 'test_helper'

class Time::ConversionsTest < ActiveSupport::TestCase
  test 'to_time should return same object' do
    yaml  = '2015-08-06 00:00:00 Z'
    time  = yaml.to_time
    time2 = time.to_time

    assert Time === time, 'time was not a Time'
    assert Time === time2, 'time2 was not a Time'

    assert_equal '06.08.2015', time.to_s
    assert_equal '06.08.2015', time2.to_s
    assert_equal time.object_id, time2.object_id
  end
end
