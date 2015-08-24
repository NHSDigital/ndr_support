# encoding: UTF-8
require 'test_helper'

# Tests Utf8Encoding::ForceBinary module.
class ForceBinaryTest < Minitest::Test
  include UTF8Encoding

  test 'binary_encode_any_high_ascii with low-ascii string' do
    input = 'manana manana'

    assert_equal 'UTF-8', input.encoding.name
    assert input.valid_encoding?

    output = binary_encode_any_high_ascii(input)

    refute_equal input.object_id, output.object_id

    assert_equal input.bytes.to_a, output.bytes.to_a
    assert_equal 'UTF-8', output.encoding.name
    assert output.valid_encoding?
  end

  test 'binary_encode_any_high_ascii with high-ascii string' do
    input = 'mañana mañana'

    assert_equal 'UTF-8', input.encoding.name
    assert input.valid_encoding?

    output = binary_encode_any_high_ascii(input)

    refute_equal input.object_id, output.object_id

    assert_equal input.bytes.to_a, output.bytes.to_a
    assert_equal 'ASCII-8BIT', output.encoding.name
    assert output.valid_encoding?
  end

  test 'binary_encode_any_high_ascii with array' do
    input  = %w(mañana manana)
    output = binary_encode_any_high_ascii(input)

    refute_equal input.object_id, output.object_id

    assert_equal %w(UTF-8 UTF-8), input.map { |str| str.encoding.name }
    assert_equal %w(ASCII-8BIT UTF-8), output.map { |str| str.encoding.name }
  end

  test 'binary_encode_any_high_ascii with hash' do
    input  = { :with => 'mañana', :without => 'manana' }
    output = binary_encode_any_high_ascii(input)

    refute_equal input.object_id, output.object_id

    assert_equal 'ASCII-8BIT', output[:with].encoding.name
    assert_equal 'UTF-8', output[:without].encoding.name
  end

  test 'binary_encode_any_high_ascii with other object' do
    input  = /mañana mañana/
    output = binary_encode_any_high_ascii(input)

    assert_equal input.object_id, output.object_id, 'should have returned same object'
  end
end
