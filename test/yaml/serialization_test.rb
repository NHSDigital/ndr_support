# encoding: UTF-8

require 'test_helper'

class SerializationTest < ActiveSupport::TestCase
  include NdrSupport::YAML::SerializationMigration
  extend  NdrSupport::YAML::EngineSelector
  extend  UTF8Encoding

  test 'should serialize then deserialize an object correctly' do
    hash = { :a => 1 }
    assert_equal hash, load_yaml(dump_yaml(hash))
  end

  test 'syck should be available properly, or not at all' do
    # See note 1 on Plan.io issue #1970.
    assert_equal [1, 2, 3], SYCK.load(SYCK.dump([1, 2, 3]))
  end if syck_available?

  test 'should handle syck-encoded data' do
    assert_syck_1_8_yaml_loads_correctly
  end

  test 'should handle syck-encoded characters with psych too' do
    stubs(:yaml_loader_for => PSYCH)
    assert_syck_1_8_yaml_loads_correctly
  end if psych_available? # We can't test this on 1.8.7

  if encoding_aware?
    test 'should handle binary yaml with control chars' do
      # irb> "\xC2\xA1null \x00 characters \r\n suck!".to_yaml
      yaml = "--- !binary |-\n  wqFudWxsIAAgY2hhcmFjdGVycyANCiBzdWNrIQ==\n"
      assert_equal "¡null 0x00 characters \r\n suck!", load_yaml(yaml)

      # irb> {fulltext: "\xC2\xA1null \x00 characters \r\n suck!"}.to_yaml
      yamled_hash = "---\n:fulltext: !binary |-\n  wqFudWxsIAAgY2hhcmFjdGVycyANCiBzdWNrIQ==\n"
      assert_equal({ :fulltext => "¡null 0x00 characters \r\n suck!" }, load_yaml(yamled_hash))
    end

    test 'load_yaml should not coerce to UTF-8 be default when using syck' do
      stubs(:yaml_loader_for => SYCK)
      assert_yaml_coercion_behaviour
    end if syck_available?

    test 'load_yaml should not coerce to UTF-8 be default when using psych' do
      stubs(:yaml_loader_for => PSYCH)
      assert_yaml_coercion_behaviour
    end if psych_available?
  end

  if psych_available? && syck_available?
    test 'time-like objects should serialise correctly with psych' do
      YAML::ENGINE.yamler = 'psych'
      NdrSupport.apply_era_date_formats! # Need applying after swapping yamler
      assert_timey_wimey_stuff
    end

    test 'time-like objects should serialise correctly with syck' do
      YAML::ENGINE.yamler = 'syck'
      NdrSupport.apply_era_date_formats! # Need applying after swapping yamler
      assert_timey_wimey_stuff
    end
  end

  private

  def assert_timey_wimey_stuff
    assert_times
    assert_dates
    assert_datetimes
    assert_datetimes_with_zones
  end

  def assert_times
    assert_nothing_raised do # Dumped by 1.9.3 syck, within era.
      loaded = YAML.load("--- !timestamp 2014-03-01\n")
      assert [Date, Time].include?(loaded.class), '1.9.3 era timestamp class'
      assert_equal 2014, loaded.year,  '1.9.3 era timestamp year'
      assert_equal 3,    loaded.month, '1.9.3 era timestamp month'
      assert_equal 1,    loaded.day,   '1.9.3 era timestamp day'
    end
  end

  def assert_dates
    date = Date.new(2014, 3, 1)

    assert_nothing_raised do # Dumped by 1.8.7 syck, within era.
      loaded = YAML.load("--- 2014-03-01\n")
      assert_equal date, loaded, '1.8.7 era date'
    end
  end

  def assert_datetimes
    datetime = DateTime.new(2014, 3, 1, 12, 45, 15)
    loaded   = YAML.load(datetime.to_yaml)

    # Datetimes serialized with Syck are loaded as Time objects...
    assert [DateTime, Time].include?(loaded.class), 'datetime class'
    assert_equal 2014, loaded.year,  'datetime year'
    assert_equal 3,    loaded.month, 'datetime month'
    assert_equal 1,    loaded.day,   'datetime day'
    assert_equal 12,   loaded.hour,  'datetime hour'
    assert_equal 45,   loaded.min,   'datetime minute'
    assert_equal 15,   loaded.sec,   'datetime second'
  end

  def assert_datetimes_with_zones
    bst_datetime = DateTime.new(2014, 4, 1, 0, 0, 0, '+1')
    bst_loaded   = load_yaml(bst_datetime.to_yaml)

    assert [DateTime, Time].include?(bst_loaded.class), 'bst datetime class'
    assert_equal 2014, bst_loaded.year,  'bst datetime year'
    assert_equal 4,    bst_loaded.month, 'bst datetime month'
    assert_equal 1,    bst_loaded.day,   'bst datetime day'
    assert_equal 0,    bst_loaded.hour,  'bst datetime hour'
    assert_equal 0,    bst_loaded.min,   'bst datetime minute'
    assert_equal 0,    bst_loaded.sec,   'bst datetime second'

    assert_equal '01.04.2014', bst_loaded.to_s

    gmt_datetime = DateTime.new(2014, 3, 1, 0, 0, 0, '+0')
    gmt_loaded   = load_yaml(gmt_datetime.to_yaml)

    assert [DateTime, Time].include?(gmt_loaded.class), 'gmt datetime class'
    assert_equal 2014, gmt_loaded.year,  'gmt datetime year'
    assert_equal 3,    gmt_loaded.month, 'gmt datetime month'
    assert_equal 1,    gmt_loaded.day,   'gmt datetime day'
    assert_equal 0,    gmt_loaded.hour,  'gmt datetime hour'
    assert_equal 0,    gmt_loaded.min,   'gmt datetime minute'
    assert_equal 0,    gmt_loaded.sec,   'gmt datetime second'

    assert_equal '01.03.2014', gmt_loaded.to_s
  end

  def assert_syck_1_8_yaml_loads_correctly
    yaml = "--- \nname: Dr. Doctor\000\000\000 \ndiagnosis: \"CIN 1 \\xE2\\x80\\x93 CIN 2\"\n"
    hash = {}

    assert_nothing_raised { hash = load_yaml(yaml) }

    # The null chars should be escaped:
    assert_equal 'Dr. Doctor0x000x000x00', hash['name']

    # The dash should be 3 bytes, but recognised as one char:
    assert_equal 15, hash['diagnosis'].bytes.to_a.length

    assert_syck_1_8_handles_encoding(hash) if encoding_aware?
  end

  def assert_syck_1_8_handles_encoding(hash)
    assert_equal 13, hash['diagnosis'].chars.to_a.length

    assert_equal 'UTF-8', hash['diagnosis'].encoding.name
    assert hash['diagnosis'].valid_encoding?
  end

  def assert_yaml_coercion_behaviour
    yaml = "---\nfulltextreport: \"Here is a weird \\x9D char\"\n"

    # By default, we'd expect the (serialised) \x9D
    assert_raises(UTF8Encoding::UTF8CoercionError) { load_yaml(yaml) }

    # With the optional second argument, we can force an escape:
    assert_nothing_raised do
      hash = load_yaml(yaml, true)
      assert_equal 'Here is a weird 0x9d char', hash['fulltextreport']
    end
  end
end
