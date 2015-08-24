require 'test_helper'

# This tests our RegexpRange class
class RegexpRangeTest < Minitest::Test
  def setup
    @lines = [
      '0Lorem ipsum dolor sit amet',
      '1consectetur adipisicing elit',
      '2sed do eiusmod tempor incididunt ut labore et dolore magna aliqua',
      '3Ut enim ad minim veniam, quis nostrud exercitation ullamco',
      '4laboris nisi ut aliquip ex ea commodo consequat'
    ]
  end

  test 'to_yaml' do
    regexp_range = RegexpRange.new(0, /^3Ut/)

    # Don't test YAML serialisation directly, but make it can be loaded:
    deserialized_regexp_range = YAML.load(regexp_range.to_yaml)
    assert_instance_of RegexpRange, deserialized_regexp_range
    assert_equal regexp_range.begin, deserialized_regexp_range.begin
    assert_equal regexp_range.end, deserialized_regexp_range.end
    assert_equal regexp_range.excl, deserialized_regexp_range.excl
  end

  test 'to_range with number and number' do
    assert_equal Range.new(2, 3, true), RegexpRange.new(2, 3, true).to_range(@lines)
    assert_equal Range.new(2, 3, false), RegexpRange.new(2, 3, false).to_range(@lines)
    assert_equal Range.new(0, -1, true), RegexpRange.new(0, -1, true).to_range(@lines)
    assert_equal Range.new(0, -1, false), RegexpRange.new(0, -1, false).to_range(@lines)

    assert_equal @lines[Range.new(2, 3, true)],
                 @lines[RegexpRange.new(2, 3, true).to_range(@lines)]
    assert_equal @lines[Range.new(2, 3, false)],
                 @lines[RegexpRange.new(2, 3, false).to_range(@lines)]
  end

  test 'to_range with number and regexp' do
    assert_equal Range.new(2, 3, true), RegexpRange.new(2, /^3Ut/, true).to_range(@lines)
    assert_equal Range.new(2, 3, false), RegexpRange.new(2, /^3Ut/, false).to_range(@lines)

    assert_equal @lines[Range.new(2, 3, true)],
                 @lines[RegexpRange.new(2, /^3Ut/, true).to_range(@lines)]
    assert_equal @lines[Range.new(2, 3, false)],
                 @lines[RegexpRange.new(2, /^3Ut/, false).to_range(@lines)]

    assert_raises RegexpRange::PatternMatchError do
      RegexpRange.new(2, /^NO_MATCH$/, true).to_range(@lines)
    end
    assert_raises RegexpRange::PatternMatchError do
      RegexpRange.new(2, /^NO_MATCH$/, false).to_range(@lines)
    end
  end

  test 'to_range with regexp and number' do
    assert_equal Range.new(1, -1, true), RegexpRange.new(/^1consec/, -1, true).to_range(@lines)
    assert_equal Range.new(1, -1, false), RegexpRange.new(/^1consec/, -1, false).to_range(@lines)
    assert_equal Range.new(1, 5, true), RegexpRange.new(/^1consec/, 5, true).to_range(@lines)
    assert_equal Range.new(1, 5, false), RegexpRange.new(/^1consec/, 5, false).to_range(@lines)

    assert_equal @lines[Range.new(1, -1, true)],
                 @lines[RegexpRange.new(/^1consec/, -1, true).to_range(@lines)]
    assert_equal @lines[Range.new(1, -1, false)],
                 @lines[RegexpRange.new(/^1consec/, -1, false).to_range(@lines)]

    assert_raises RegexpRange::PatternMatchError do
      RegexpRange.new(/^NO_MATCH$/, 5, true).to_range(@lines)
    end
    assert_raises RegexpRange::PatternMatchError do
      RegexpRange.new(/^NO_MATCH$/, 5, false).to_range(@lines)
    end
  end

  test 'to_range with regexp and regexp' do
    assert_equal Range.new(1, 3, true),
                 RegexpRange.new(/^1consec/, /^3Ut/, true).to_range(@lines)
    assert_equal Range.new(1, 3, false),
                 RegexpRange.new(/^1consec/, /^3Ut/, false).to_range(@lines)

    assert_equal @lines[Range.new(1, 3, true)],
                 @lines[RegexpRange.new(/^1consec/, /^3Ut/, true).to_range(@lines)]
    assert_equal @lines[Range.new(1, 3, false)],
                 @lines[RegexpRange.new(/^1consec/, /^3Ut/, false).to_range(@lines)]

    assert_raises RegexpRange::PatternMatchError do
      RegexpRange.new(/^NO_MATCH$/, /^NO_MATCH$/, true).to_range(@lines)
    end
    assert_raises RegexpRange::PatternMatchError do
      RegexpRange.new(/^NO_MATCH$/, /^NO_MATCH$/, false).to_range(@lines)
    end
  end

  test 'comparison to self' do
    rr1 = RegexpRange.new(/start/, /end/, false)
    assert_equal rr1, rr1
  end

  test 'comparison to identical regexprange' do
    rr1 = RegexpRange.new(/start/, /end/, false)
    rr2 = RegexpRange.new(/start/, /end/, false)
    assert_equal rr1, rr2
  end

  test 'comparison to different regexprange' do
    rr1 = RegexpRange.new(/start/, /end/, false)
    rr2 = RegexpRange.new(/start/, /end/, true)
    refute_equal rr1, rr2

    rr3 = RegexpRange.new(/start/, /end/, false)
    rr4 = RegexpRange.new(/start/, /finish/, false)
    refute_equal rr3, rr4

    rr5 = RegexpRange.new(/start/, /end/, true)
    rr6 = RegexpRange.new(/begin/, /end/, true)
    refute_equal rr5, rr6
  end

  test 'hash key comparison' do
    rr1 = RegexpRange.new(/start/, /end/, false)
    rr2 = RegexpRange.new(/start/, /end/, false)
    rr3 = RegexpRange.new(/start/, /end/, true)

    hash = Hash.new { |h, k| h[k] = 0 }

    hash[rr1] += 1
    hash[rr2] += 1
    hash[rr3] += 1

    assert_equal 2, hash.keys.length

    assert_equal 2, hash[rr1]
    assert_equal 2, hash[rr2]
    assert_equal 1, hash[rr3]
  end
end
