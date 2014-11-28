require 'test_helper'

class ArrayTest < ActiveSupport::TestCase
  test "Arrays should be extended with #permutations" do
    assert [].respond_to?(:permutations)
  end

  test "Array#permutations should calculate permutations correctly" do
    array = [1, 2, 3]
    permutations = [ [1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1] ]
    assert_equal array.length.factorial, array.permutations.length
    assert_same_elements permutations, array.permutations
  end

  test "Array#permutations should permute duplicates" do
    array = [1, 1]
    assert_equal [[1, 1], [1, 1]], array.permutations
  end
end