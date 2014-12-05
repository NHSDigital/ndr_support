require 'test_helper'

# This tests our RegexpRange class
class RegexpRangeTest < ActiveSupport::TestCase
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

    yaml = <<YAML
--- !ruby/object:RegexpRange
begin: 0
end: !ruby/regexp /^3Ut/
excl: false
YAML
    assert_equal yaml, regexp_range.to_yaml

    deserialized_regexp_range = Psych.load(regexp_range.to_yaml)
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

    assert_raise RegexpRange::PatternMatchError do
      RegexpRange.new(2, /^NO_MATCH$/, true).to_range(@lines)
    end
    assert_raise RegexpRange::PatternMatchError do
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

    assert_raise RegexpRange::PatternMatchError do
      RegexpRange.new(/^NO_MATCH$/, 5, true).to_range(@lines)
    end
    assert_raise RegexpRange::PatternMatchError do
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

    assert_raise RegexpRange::PatternMatchError do
      RegexpRange.new(/^NO_MATCH$/, /^NO_MATCH$/, true).to_range(@lines)
    end
    assert_raise RegexpRange::PatternMatchError do
      RegexpRange.new(/^NO_MATCH$/, /^NO_MATCH$/, false).to_range(@lines)
    end
  end
end
