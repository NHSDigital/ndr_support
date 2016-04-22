require 'test_helper'

class String
  class CleaningTest < Minitest::Test
    # squash

    test 'postcodeize' do
      assert_equal 'CB22 3AD', 'CB223AD'.postcodeize
      assert_equal 'CB2 2QQ', 'CB22QQ'.postcodeize
      assert_equal 'CB2 2QQ', 'CB22QQ  '.postcodeize
      assert_equal 'CB2 2QQ', 'C   B   22QQ  '.postcodeize
      assert_equal 'CB22QQ', 'CB2 2QQ'.postcodeize(:compact)
      assert_equal 'CB2 2QQ', 'CB22QQ  '.postcodeize(:db)
      assert_equal 'CB2A2QQ', 'CB2A 2QQ  '.postcodeize(:db)
      assert_equal '', ''.postcodeize
      assert_equal 'CB2 2QQ', 'cb22qq'.postcodeize(:db)
      # Database storage format for all major UK postcode formats:
      assert_equal 'A9  9AA', 'A9 9AA'.postcodeize(:db)
      assert_equal 'A99 9AA', 'A99 9AA'.postcodeize(:db)
      assert_equal 'A9A 9AA', 'A9A 9AA'.postcodeize(:db)
      assert_equal 'AA9 9AA', 'AA9 9AA'.postcodeize(:db)
      assert_equal 'AA999AA', 'AA99 9AA'.postcodeize(:db)
      assert_equal 'AA9A9AA', 'AA9A 9AA'.postcodeize(:db)
      # Examples of legacy postcodes, that should be unchanged
      assert_equal 'IP222', 'IP222'.postcodeize(:db)
      assert_equal 'IP222E', 'IP222E'.postcodeize(:db)
      assert_equal 'HANTS', 'HANTS'.postcodeize(:db)
    end

    test 'xml_unsafe?' do
      without_control = 'hello world!'
      refute without_control.xml_unsafe?

      with_safe_control = "increase: 100\045"
      refute with_safe_control.xml_unsafe?

      with_unsafe_control = "Lorem \000Ipsum\000"
      assert with_unsafe_control.xml_unsafe?
    end

    test 'strip_xml_unsafe_characters' do
      without_control = 'hello world!'
      assert_equal without_control, without_control.strip_xml_unsafe_characters

      with_safe_control = "increase: 100\045"
      assert_equal 'increase: 100%', with_safe_control.strip_xml_unsafe_characters

      with_unsafe_control = "Lorem \000Ipsum\000"
      assert_equal 'Lorem Ipsum', with_unsafe_control.strip_xml_unsafe_characters
    end

    test 'clean xmlsafe' do
      without_control = 'hello world!'
      assert_equal without_control, without_control.clean(:xmlsafe)

      with_safe_control = "increase: 100\045"
      assert_equal 'increase: 100%', with_safe_control.clean(:xmlsafe)

      with_unsafe_control = "Lorem \007Ipsum\006"
      assert_equal 'Lorem Ipsum', with_unsafe_control.clean(:xmlsafe)
    end

    test 'clean make_xml_safe' do
      without_control = 'hello world!'
      assert_equal without_control, without_control.clean(:make_xml_safe)

      with_safe_control = "increase: 100\045"
      assert_equal 'increase: 100%', with_safe_control.clean(:make_xml_safe)

      with_unsafe_control = "Lorem \000Ipsum\000"
      assert_equal 'Lorem Ipsum', with_unsafe_control.clean(:make_xml_safe)
    end

    test 'clean nhsnumber' do
      assert_equal '1234567890', '123 456 7890'.clean(:nhsnumber)
      assert_equal '1234567890', '    123-456-7890123'.clean(:nhsnumber)
      assert_equal '', 'unknown'.clean(:nhsnumber)
      assert_equal '', ''.clean(:nhsnumber)
    end

    test 'clean postcode' do
      assert_equal 'CB4 3ND', 'cb4   3ND '.clean(:postcode)
      assert_equal 'CB223AD', ' CB22 3AD'.clean(:postcode)
      assert_equal '', ''.clean(:postcode)
    end

    test 'clean lpi' do
      #   self.upcase.delete('^0-9A-Z')
      assert_equal '007', '007?!?'.clean(:lpi)
      assert_equal 'A0000001', 'a0000001'.clean(:lpi)
      assert_equal 'UNKNOWN', 'UNKNOWN'.clean(:lpi)
      assert_equal '', ''.clean(:lpi)
    end

    test 'clean sex' do
      assert_equal '1', 'male'.clean(:sex)
      assert_equal '1', '1'.clean(:sex)
      assert_equal '2', 'F'.clean(:sex)
      assert_equal '2', '2'.clean(:sex)
      assert_equal '0', ''.clean(:sex)
      assert_equal '0', 'unknown'.clean(:sex)
    end

    test 'clean sex_c' do
      assert_equal 'M', 'male'.clean(:sex_c)
      assert_equal 'M', '1'.clean(:sex_c)
      assert_equal 'F', 'F'.clean(:sex_c)
      assert_equal 'F', '2'.clean(:sex_c)
      assert_equal '', ''.clean(:sex_c)
      assert_equal '', 'unknown'.clean(:sex_c)
    end

    test 'clean name' do
      assert_equal 'MAKE A NAME', ' Make A. Name       '.clean(:name)
      assert_equal 'PUNCTUATE A NAME', 'PUNCTUATE,A;NAME'.clean(:name)
      assert_equal 'SPREAD A NAME', 'spread    a      name'.clean(:name)
      assert_equal "O'NAME", 'O`NAME'.clean(:name)
      assert_equal "JOHN MIDDLE O'NAME", 'John,  Middle.   O`NAME'.clean(:name)
      assert_equal '', ''.clean(:name)
    end

    test 'clean ethniccategory' do
      assert_equal 'M', '1'.clean(:ethniccategory)
      assert_equal 'X', '99'.clean(:ethniccategory)
      assert_equal 'A', 'A'.clean(:ethniccategory)
      assert_equal 'INVALID', 'InValid'.clean(:ethniccategory)
      assert_equal '', ''.clean(:ethniccategory)
    end

    test 'clean code' do
      assert_equal 'a123 B456', ' a12.3,,B45.6;'.clean(:code)
      assert_equal 'A123 B456', 'A12.3 B.456'.clean(:code)
      assert_equal 'UNKNOWN', 'UNKNOWN'.clean(:code)
      assert_equal '', ''.clean(:code)
    end

    test 'clean code_icd' do
      # TODO
    end

    test 'clean icd' do
      assert_equal 'C509', '  c50.9; '.clean(:icd)
      assert_equal 'C50 C509', ' C50X, c50.9; '.clean(:icd)
      assert_equal 'D04', 'd04'.clean(:icd)
      assert_equal 'C32', ';C32.X'.clean(:icd)
    end

    test 'clean code_opcs' do
      assert_equal 'B274 Z943', ' b27.4,Z94.3;'.clean(:code_opcs)
      assert_equal 'B274 Z943', 'B27.4 Z94.3'.clean(:code_opcs)
      assert_equal 'CZ001', 'CZ001'.clean(:code_opcs)
      assert_equal 'B274 CZ002', 'B27.4 cz00.2'.clean(:code_opcs)
      assert_equal '', 'CZ003'.clean(:code_opcs)
      assert_equal '', 'UNKNOWN'.clean(:code_opcs)
      assert_equal '', ''.clean(:code_opcs)
    end

    test 'clean hospitalnumber' do
      assert_equal 'a0000001', 'a0000001'.clean(:hospitalnumber)
      assert_equal 'A0000001', 'A0000001B'.clean(:hospitalnumber)
      assert_equal 'UNKNOW', 'UNKNOWN'.clean(:hospitalnumber)
      assert_equal '', ''.clean(:hospitalnumber)
    end

    test 'clean tnmcategory' do
      assert_equal '', ''.clean(:tnmcategory)
      assert_equal 'X', 'X'.clean(:tnmcategory)
      assert_equal 'X', 'x'.clean(:tnmcategory)
      assert_equal '1a', '1A'.clean(:tnmcategory)
      assert_equal '1a', '1a'.clean(:tnmcategory)
      assert_equal '1a', 'T1A'.clean(:tnmcategory)
      assert_equal '1a', 't1a'.clean(:tnmcategory)
      assert_equal 'X', 'TX'.clean(:tnmcategory)
      assert_equal 'X', 'tx'.clean(:tnmcategory)
      assert_equal 'X', 'Tx'.clean(:tnmcategory)
      assert_equal 'X', 'tX'.clean(:tnmcategory)
    end

    test 'clean upcase' do
      assert_equal '', ''.clean(:upcase)
      assert_equal 'DOWNCASE', 'downcase'.clean(:upcase)
      assert_equal 'MIXEDCASE', 'mIxEdCaSe'.clean(:upcase)
      assert_equal 'UPCASE', 'UPCASE'.clean(:upcase)
    end

    test 'clean fallback' do
      assert_equal 'UN KNOWN', 'UN ?KNOWN'.clean(:somethingorother)
      assert_equal 'UNKNOWN', 'UNKNOWN'.clean(:somethingorother)
      assert_equal '', ''.clean(:somethingorother)
    end
  end
end
