require 'test/unit'
require 'active_support/test_case'
require 'ndr_support'

class ActiveSupport::TestCase
  # A useful helper to make 'assert !condition' statements more readable
  def deny(condition, message='No further information given')
    assert !condition, message
  end
end
