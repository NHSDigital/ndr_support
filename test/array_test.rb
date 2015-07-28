require 'test_helper'

# This tests our Array extension
class ArrayTest < Minitest::Test
  test 'Arrays should be extended with #permutations' do
    assert [].respond_to?(:permutations)
  end

  test 'Array#permutations should calculate permutations correctly' do
    array = [1, 2, 3]
    permutations = [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
    assert_equal array.length.factorial, array.permutations.length
    assert_equal permutations.sort, array.permutations.sort
  end

  test 'Array#permutations should permute duplicates' do
    array = [1, 1]
    assert_equal [[1, 1], [1, 1]], array.permutations
  end
end
