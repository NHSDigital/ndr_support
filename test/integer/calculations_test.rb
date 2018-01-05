require 'test_helper'

# This tests our Integer calculations extension
class Integer::CalculationsTest < Minitest::Test
  test 'Integer should be extended with #factorial' do
    assert 1.respond_to?(:factorial)
  end

  test 'Integer#factorial should behave correctly' do
    assert_equal 1, 0.factorial
    assert_equal 24, 4.factorial
    assert_raises(RuntimeError) { -1.factorial }
  end

  test 'Integer should be extended with #choose' do
    assert 1.respond_to?(:choose)
  end

  test 'Integer#choose should behave correctly' do
    pascal_row = [1, 5, 10, 10, 5, 1]
    pascal_row.each_with_index do |target, index|
      assert_equal target, 5.choose(index)
    end

    assert_raises(ArgumentError) { 10.choose(11) }
    assert_raises(ArgumentError) { 10.choose(-1) }
  end
end
