require 'test_helper'

# Tests password generation and checking library
class PasswordTest < Minitest::Test
  test 'checking length requirement' do
    refute NdrSupport::Password.valid?('acegi')
    assert NdrSupport::Password.valid?('acegik')
  end

  test 'checking character uniqueness requirement' do
    refute NdrSupport::Password.valid?('acegacegacegacegacegacegaceg')
    assert NdrSupport::Password.valid?('acefhacefhacefhacefhacefhace')
  end

  test 'when checking, dictionary words are considered' do
    refute NdrSupport::Password.valid?('google password')
    assert NdrSupport::Password.valid?('google the password')
  end

  test 'when checking, custom dictionary words are considered' do
    refute NdrSupport::Password.valid?('google passphrase',     word_list: ['passphrase'])
    assert NdrSupport::Password.valid?('google the passphrase', word_list: ['passphrase'])
  end

  test 'when checking, custom dictionary words that are also sequences are not over-counted' do
    refute NdrSupport::Password.valid?('hijkl a ',  word_list: %w(hijkl hijklm))
    refute NdrSupport::Password.valid?('hijklm a ', word_list: %w(hijkl hijklm))
  end

  test 'when checking, custom dictionary words substrings of others should not intefere' do
    refute NdrSupport::Password.valid?('acegik a', word_list: %w(cegi acegik))
    refute NdrSupport::Password.valid?('acegik a', word_list: %w(acegik cegi))
  end

  test 'checking blank input' do
    refute NdrSupport::Password.valid?(nil)
    refute NdrSupport::Password.valid?('')
    refute NdrSupport::Password.valid?('                    ')
  end

  test 'checking with increasing sequences' do
    refute NdrSupport::Password.valid?('12345678')
    refute NdrSupport::Password.valid?('1234 5678')
    refute NdrSupport::Password.valid?('456789')
    refute NdrSupport::Password.valid?('456 789')
    refute NdrSupport::Password.valid?('abcdefghijk')
    refute NdrSupport::Password.valid?('abcde fghijk')
    refute NdrSupport::Password.valid?('BCDEFGHIJKL')
    refute NdrSupport::Password.valid?('BCDEFG HIJKL')

    assert NdrSupport::Password.valid?('more 1234 5678')
    assert NdrSupport::Password.valid?('1234 more 5678')
    assert NdrSupport::Password.valid?('1234 5678 more')
  end

  test 'checking with decreasing sequences' do
    refute NdrSupport::Password.valid?('87654321')
    refute NdrSupport::Password.valid?('8765 4321')
    refute NdrSupport::Password.valid?('987654')
    refute NdrSupport::Password.valid?('987 654')
    refute NdrSupport::Password.valid?('kjihgfedcba')
    refute NdrSupport::Password.valid?('kjihg fedcba')
    refute NdrSupport::Password.valid?('LKJIHGFEDCB')
    refute NdrSupport::Password.valid?('LKJIHG FEDCB')

    assert NdrSupport::Password.valid?('more 8765 4321')
    assert NdrSupport::Password.valid?('8765 more 4321')
    assert NdrSupport::Password.valid?('8765 4321 more')
  end

  test 'checking with increasing then decreasing sequences' do
    refute NdrSupport::Password.valid?('123456787654321')
    refute NdrSupport::Password.valid?('aBcDeFgFeDcBa')

    assert NdrSupport::Password.valid?('something 123456787654321')
    assert NdrSupport::Password.valid?('something aBcDeFgFeDcBa')
  end

  test 'checking with decreasing then increasing sequences' do
    refute NdrSupport::Password.valid?('876543212345678')
    refute NdrSupport::Password.valid?('gFeDcBaBcDeFg')

    assert NdrSupport::Password.valid?('something 876543212345678')
    assert NdrSupport::Password.valid?('something gFeDcBaBcDeFg')
  end

  test 'checking with repeating characters' do
    refute NdrSupport::Password.valid?('happen')
    assert NdrSupport::Password.valid?('happens')
    assert NdrSupport::Password.valid?('hapqren')
    assert NdrSupport::Password.valid?('hapqsen')

    refute NdrSupport::Password.valid?('balloon')
    refute NdrSupport::Password.valid?('ballllLLLllLLLllllooooOOooOOoooon')
    assert NdrSupport::Password.valid?('baileon')
  end

  test 'generating' do
    password = NdrSupport::Password.generate

    assert NdrSupport::Password.valid?(password)
    assert_equal 4, password.split(/\s/).length

    password.scan(/\w+/) { |wd| assert NdrSupport::Password::RFC1751_WORDS.include?(wd.upcase) }
  end

  test 'generating with custom length' do
    password = NdrSupport::Password.generate(number_of_words: 6)

    assert NdrSupport::Password.valid?(password)
    assert_equal 6, password.split(/\s/).length

    password.scan(/\w+/) { |wd| assert NdrSupport::Password::RFC1751_WORDS.include?(wd.upcase) }
  end

  test 'generating with custom separator' do
    password = NdrSupport::Password.generate(separator: '-')

    assert NdrSupport::Password.valid?(password)
    assert_equal 4, password.split(/-/).length

    password.scan(/\w+/) { |wd| assert NdrSupport::Password::RFC1751_WORDS.include?(wd.upcase) }
  end

  test 'generating unrealistically' do
    exception = assert_raises(RuntimeError) { NdrSupport::Password.generate(number_of_words: 1) }
    assert_match(/failed to generate/i, exception.message)
  end
end
