require 'test_helper'

# This tests our Hash extension
class HashTest < ActiveSupport::TestCase
  test 'value_by_path' do
    my_hash = { 'one' => '1', 'two' => { 'twopointone' => '2.1', 'twopointtwo' => '2.2' } }
    assert_equal my_hash['one'], my_hash.value_by_path('one')
    assert_equal my_hash['two']['twopointone'], my_hash.value_by_path('two', 'twopointone')
  end

  test 'intersection' do
    my_hash = { :a => 1, :b => :two, 'c' => '3' }
    assert_equal({ :a => 1, 'c' => '3' }, my_hash & [:a, :c])
    assert_equal({ :b => :two }, my_hash & [:b])
    assert_equal({}, my_hash & [:d, :e])
  end

  test 'rawtext_merge without prevent_overwrite' do
    first_hash = { :a => 1, :b => :two, :rawtext => { 'x' => 'apples', 'y' => 'pears' } }
    second_hash = { :b => 2, 'c' => '3', :rawtext => { 'y' => 'pears', 'z' => 'oranges' } }
    assert_equal(
      {
        :a => 1, :b => 2, 'c' => '3',
        :rawtext => { 'x' => 'apples', 'y' => 'pears', 'z' => 'oranges' }
      },
      first_hash.rawtext_merge(second_hash, false)
    )
    # Ensure original hashes are preserved
    assert_equal(
      { :a => 1, :b => :two, :rawtext => { 'x' => 'apples', 'y' => 'pears' } }, first_hash
    )
    assert_equal(
      { :b => 2, 'c' => '3', :rawtext => { 'y' => 'pears', 'z' => 'oranges' } }, second_hash
    )
  end

  test 'rawtext_merge with prevent_overwrite on rawtext' do
    first_hash = { :a => 1, :b => :two, :rawtext => { 'x' => 'apples', 'y' => 'pears' } }
    second_hash = { 'c' => '3', :rawtext => { 'y' => 'pears', 'z' => 'oranges' } }
    assert_raise RuntimeError do
      first_hash.rawtext_merge(second_hash, true)
    end
    # Ensure original hashes are preserved
    assert_equal(
      { :a => 1, :b => :two, :rawtext => { 'x' => 'apples', 'y' => 'pears' } }, first_hash
    )
    assert_equal({ 'c' => '3', :rawtext => { 'y' => 'pears', 'z' => 'oranges' } }, second_hash)
  end

  test 'rawtext_merge with prevent_overwrite on non-rawtext' do
    first_hash = { :a => 1, :b => :two, :rawtext => { 'x' => 'apples' } }
    second_hash = { :b => 2, 'c' => '3', :rawtext => { 'y' => 'pears', 'z' => 'oranges' } }
    assert_raise RuntimeError do
      first_hash.rawtext_merge(second_hash, true)
    end
    # Ensure original hashes are preserved
    assert_equal({ :a => 1, :b => :two, :rawtext => { 'x' => 'apples' } }, first_hash)
    assert_equal(
      { :b => 2, 'c' => '3', :rawtext => { 'y' => 'pears', 'z' => 'oranges' } }, second_hash
    )
  end

  test 'rawtext_merge with one rawtext missing' do
    first_hash = { :a => 1, :b => :two }
    second_hash = { 'c' => '3', :rawtext => { 'x' => 'apples' } }
    assert_equal({ :a => 1, :b => :two, 'c' => '3', :rawtext => { 'x' => 'apples' } },
                 first_hash.rawtext_merge(second_hash, false))
    assert_equal({ :a => 1, :b => :two, 'c' => '3', :rawtext => { 'x' => 'apples' } },
                 second_hash.rawtext_merge(first_hash, false))
    # Ensure original hashes are preserved
    assert_equal({ :a => 1, :b => :two }, first_hash)
    assert_equal({ 'c' => '3', :rawtext => { 'x' => 'apples' } }, second_hash)
  end

  test 'rawtext_merge with rawtext missing' do
    first_hash = { :a => 1, :b => :two }
    second_hash = { 'c' => '3' }
    assert_equal({ :a => 1, :b => :two, 'c' => '3', :rawtext => {} },
                 first_hash.rawtext_merge(second_hash, false))
    # Ensure original hashes are preserved
    assert_equal({ :a => 1, :b => :two }, first_hash)
    assert_equal({ 'c' => '3' }, second_hash)
  end
end
