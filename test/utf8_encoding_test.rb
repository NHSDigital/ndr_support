require 'test_helper'

class Utf8EncodingTest < ActiveSupport::TestCase
  extend UTF8Encoding
  include UTF8Encoding

  test 'ensure_utf8 should return a new string' do
    string1 = 'hello'
    string2 = ensure_utf8(string1)

    deny string1.object_id == string2.object_id
  end

  test 'ensure_utf8! should return the same string' do
    string1 = 'hello'
    string2 = ensure_utf8!(string1)

    assert string1.object_id == string2.object_id
  end

  test 'ensure_utf8_object! should work with arrays' do
    array = []
    expects(:ensure_utf8_array!).with(array).returns(array)
    assert_equal array, ensure_utf8_object!(array)
  end

  test 'ensure_utf8_array! should work on elements' do
    element1 = 'hello'
    element2 = :world
    array = [element1, element2]

    expects(:ensure_utf8_object!).with(element1)
    expects(:ensure_utf8_object!).with(element2)

    assert_equal array, ensure_utf8_array!(array)
  end

  test 'ensure_utf8_object! should work with hashes' do
    hash = {}
    expects(:ensure_utf8_hash!).with(hash).returns(hash)
    assert_equal hash, ensure_utf8_object!(hash)
  end

  test 'ensure_utf8_hash! should work on values' do
    element1 = 'hello'
    element2 = :world
    hash = { element1 => element2 }

    expects(:ensure_utf8_object!).with(element1).never
    expects(:ensure_utf8_object!).with(element2)

    assert_equal hash, ensure_utf8_hash!(hash)
  end

  test 'ensure_utf8_object! should work with strings' do
    string = ''
    expects(:ensure_utf8!).with(string).returns(string)
    assert_equal string, ensure_utf8_object!(string)
  end

  if encoding_aware?
    test 'ensure_utf8 should convert low bytes to UTF-8 if possible' do
      string1 = 'hello'.force_encoding('Windows-1252')
      string2 = ensure_utf8!(string1)

      assert_equal string1, string2
      assert_equal 'UTF-8', string2.encoding.name
    end

    test 'ensure_utf8 should convert high bytes to UTF-8 if possible' do
      string1 = "dash \x96 dash".force_encoding('Windows-1252')
      assert_equal 11, string1.bytes.to_a.length
      assert_equal 11, string1.chars.to_a.length

      assert string1.valid_encoding?

      string2 = ensure_utf8(string1)
      assert_equal 13, string2.bytes.to_a.length
      assert_equal 11, string2.chars.to_a.length

      assert_equal 'UTF-8', string2.encoding.name
      assert string2.valid_encoding?
    end

    test 'ensure_utf8 should prefer a given encoding' do
      string1 = "japan \x8E\xA6 ese"
      assert_equal 12, string1.bytes.to_a.length
      assert_equal 12, string1.chars.to_a.length

      string2 = ensure_utf8(string1, 'EUC-JP')
      assert_equal 13, string2.bytes.to_a.length
      assert_equal 11, string2.chars.to_a.length

      # "halfwidth katakana letter wo":
      assert_equal [239, 189, 166], string2.bytes.to_a[6...9]

      assert_equal 'UTF-8', string2.encoding.name
      assert string2.valid_encoding?
    end

    test 'ensure_utf8 should fail if unable to derive encoding' do
      assert_raise(UTF8Encoding::UTF8CoercionError) do
        # Not going to work with UTF-8 or Windows-1252:
        ensure_utf8("rubbish \x90 rubbish")
      end
    end
  end

end
