require 'test_helper'

# This tests our rounding extension
class Integer::RoundingTest < Minitest::Test
  def test_rounding
    assert_equal 124_000, 123_221.round_up_to(3)
    assert_equal 123_300, 123_221.round_up_to(4)
    assert_equal 760, 758.round_up_to(2)
    assert_equal 3453, 3452.round_up_to(4)
    assert_nil 1.round_up_to(2)
    refute_nil 10.round_up_to(2)
    assert_nil 12.round_up_to(-45)
  end
end
