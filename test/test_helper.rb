require 'test/unit'
require 'active_support/test_case'
require 'active_support/time'
require 'ndr_support'

# Override default date and time formats:
Date::DATE_FORMATS.update(
  {:db => '%Y-%m-%d %H:%M:%S', :ui => '%d.%m.%Y', :default => '%d.%m.%Y'}
)
# Rails 2 loads Oracle dates (with timestamps) as DateTime or Time values
# (before or after 1970) whereas Rails 1.2 treated them as Date objects.
# Therefore we have a formatting challenge, which we overcome by hiding
# the time if it's exactly midnight
Time::DATE_FORMATS.update(
  {:db => '%Y-%m-%d %H:%M:%S', :ui => '%d.%m.%Y %H:%M',
  :default => lambda{ |time|
    time.strftime(time.hour != 0 || time.min != 0 || time.sec != 0 ?
                  '%d.%m.%Y %H:%M' : '%d.%m.%Y')}}
)

class ActiveSupport::TestCase
  # A useful helper to make 'assert !condition' statements more readable
  def deny(condition, message='No further information given')
    assert !condition, message
  end
end
