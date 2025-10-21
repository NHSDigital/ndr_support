require 'test_helper'

# Tests Utf8Encoding::ControlCharacters module.
class ControlCharactersTest < Minitest::Test
  include UTF8Encoding

  test 'control char identification' do
    (0..255).each do |code|
      expected = code == 127 || (code < 32 && [9, 10, 13].exclude?(code)) ? 4 : 1
      actual   = escape_control_chars(code.chr).length

      assert_equal expected, actual, "unexpected escaping for value: #{code} (#{code.chr})"
    end
  end

  test 'escape_control_chars with harmless string' do
    string   = 'null \x00 characters suck'
    expected = 'null \x00 characters suck'
    actual   = escape_control_chars(string)

    assert_equal expected, actual
    refute actual.object_id == string.object_id, 'should not have modified in place'
  end

  test 'escape_control_chars! with harmless string' do
    string   = +'null \x00 characters suck'
    expected = 'null \x00 characters suck'
    actual   = escape_control_chars!(string)

    assert_equal expected, actual
    assert_equal actual.object_id, string.object_id
  end

  test 'escape_control_chars with unprintable control characters' do
    string   = "null \x00 \x7F characters suck"
    expected = 'null 0x00 0x7f characters suck'
    actual   = escape_control_chars(string)

    assert_equal expected, actual
    refute actual.object_id == string.object_id, 'should not have modified in place'
  end

  test 'escape_control_chars! with unprintable control characters' do
    string   = +"null \x00 characters suck"
    expected = 'null 0x00 characters suck'
    actual   = escape_control_chars!(string)

    assert_equal expected, actual
    assert_equal string.object_id, actual.object_id
  end

  test 'escape_control_chars! with printable control characters' do
    string   = +"null \x00 characters \r\n really \t suck \x07\x07\x07"
    expected = "null 0x00 characters \r\n really \t suck 0x070x070x07" # ring ring ring

    assert_equal expected, escape_control_chars!(string)
  end

  test 'escape_control_chars_in_object! with array' do
    array    = %W[hello\tcruel \x00 world!\n \x07].collect(&:dup)
    expected = %W[hello\tcruel 0x00 world!\n 0x07]
    actual   = escape_control_chars_in_object!(array)

    assert_equal expected, actual
    assert_equal array.object_id, actual.object_id
  end

  test 'escape_control_chars_in_object! with hash' do
    hash     = { a: +"hello\tcruel", b: +"\x00", c: +"world!\n", d: +"\x07" }
    expected = { a: "hello\tcruel", b: '0x00', c: "world!\n", d: '0x07' }
    actual   = escape_control_chars_in_object!(hash)

    assert_equal expected, actual
    assert_equal hash.object_id, actual.object_id
  end

  test 'escape_control_chars_in_object! with PORO' do
    object  = Object.new
    escaped = escape_control_chars_in_object!(object)

    assert_equal object, escaped
    assert_equal object.object_id, escaped.object_id
  end
end
