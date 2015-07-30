require 'test_helper'

# This tests our Nil extension
class NilTest < Minitest::Test
  test 'to_date' do
    assert_nil nil.to_date
  end

  test 'titleize' do
    assert_nil nil.titleize
  end

  test 'surnameize' do
    assert_nil nil.surnameize
  end

  test 'postcodeize' do
    assert_nil nil.postcodeize
  end

  test 'upcase' do
    assert_nil nil.upcase
  end

  test 'clean' do
    assert_nil nil.clean(:tnmcategory)
  end

  test 'squash' do
    assert_nil nil.squash
  end

  test 'gsub' do
    assert_equal '', nil.gsub(/.*/)
  end

  test 'strip' do
    assert_nil nil.strip
  end
end
