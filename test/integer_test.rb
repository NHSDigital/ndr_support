require 'test_helper'

class IntegerTest < ActiveSupport::TestCase
  def test_rounding
    assert_equal 124000, 123221.round_up_to(3)
    assert_equal 123300, 123221.round_up_to(4)
    assert_equal 760, 758.round_up_to(2)
    assert_equal 3453, 3452.round_up_to(4)
    assert_nil 1.round_up_to(2)
    assert_not_nil 10.round_up_to(2)
    assert_nil 12.round_up_to(-45)
  end
end
