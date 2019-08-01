require 'test_helper'

# This tests our Integer working days extension
class Integer::WorkingDaysTest < Minitest::Test
  test 'Integer should be extended with #working_days_since' do
    assert 1.respond_to?(:working_days_since)
  end

  test 'Integer#working_days_since should behave correctly' do
    assert_equal Date.new(2019, 12, 23), 1.working_days_since(Date.new(2019, 12, 20))
    assert_equal Date.new(2019, 12, 27), 3.working_days_since(Date.new(2019, 12, 20))
    assert_equal Date.new(2019, 12, 30), 4.working_days_since(Date.new(2019, 12, 20))
  end
end
