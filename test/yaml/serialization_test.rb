# encoding: UTF-8

require 'test_helper'

class SerializationTest < Minitest::Test
  include NdrSupport::YAML::SerializationMigration

  test 'should serialize then deserialize an object correctly' do
    hash = { :a => 1 }
    assert_equal hash, load_yaml(dump_yaml(hash))
  end

  test 'should handle syck-encoded characters' do
    assert_syck_1_8_yaml_loads_correctly
  end

  test 'should handle binary yaml with control chars' do
    # irb> "\xC2\xA1null \x00 characters \r\n suck!".to_yaml
    yaml = "--- !binary |-\n  wqFudWxsIAAgY2hhcmFjdGVycyANCiBzdWNrIQ==\n"
    assert_equal "¡null 0x00 characters \r\n suck!", load_yaml(yaml)

    # irb> {fulltext: "\xC2\xA1null \x00 characters \r\n suck!"}.to_yaml
    yamled_hash = "---\n:fulltext: !binary |-\n  wqFudWxsIAAgY2hhcmFjdGVycyANCiBzdWNrIQ==\n"
    assert_equal({ :fulltext => "¡null 0x00 characters \r\n suck!" }, load_yaml(yamled_hash))
  end

  # Psych doesn't always base64-encode control characters:
  test 'should handle non-binary yaml with control chars' do
    #irb> Psych.dump("control \x01 char \n whoops!")
    chr_1_yaml = "--- ! \"control \\x01 char \\n whoops!\"\n"
    assert_equal "control 0x01 char \n whoops!", load_yaml(chr_1_yaml)
  end

  test 'load_yaml should not coerce to UTF-8 by default' do
    assert_yaml_coercion_behaviour
  end

  test 'dump_yaml should produce encoding-portable YAML' do
    original_object = { :basic => 'manana', :complex => 'mañana' }
    yaml_produced   = dump_yaml(original_object)
    reloaded_object = load_yaml(yaml_produced)

    assert yaml_produced =~ /basic: manana/, 'binary-encoded more than was necessary'

    refute yaml_produced.bytes.detect { |byte| byte > 127 }, 'yaml has high-ascii'
    assert reloaded_object.inspect.bytes.detect { |byte| byte > 127 }
    assert_equal original_object, reloaded_object
  end

  test 'encoding-portable YAML should be loadable' do
    original_object = { :basic => 'manana', :complex => 'mañana' }
    yaml_produced   = dump_yaml(original_object)

    reloaded_object = load_yaml(yaml_produced)
    assert_equal original_object, reloaded_object
  end

  test 'time-like objects should serialise correctly with psych' do
    assert_timey_wimey_stuff
  end

  private

  def assert_timey_wimey_stuff
    assert_times
    assert_dates
    assert_datetimes
    assert_datetimes_with_zones
  end

  def assert_times
    # Dumped by 1.9.3 syck, within era.
    loaded = YAML.load("--- !timestamp 2014-03-01\n")
    assert [Date, Time].include?(loaded.class), '1.9.3 era timestamp class'
    assert_equal 2014, loaded.year,  '1.9.3 era timestamp year'
    assert_equal 3,    loaded.month, '1.9.3 era timestamp month'
    assert_equal 1,    loaded.day,   '1.9.3 era timestamp day'
  end

  def assert_dates
    date = Date.new(2014, 3, 1)

    # Dumped by 1.8.7 syck, within era.
    loaded = YAML.load("--- 2014-03-01\n")
    assert_equal date, loaded, '1.8.7 era date'

    # Check default formatting does not affect serialisation:
    assert_equal '01.03.2014', date.to_s
    assert_equal date, YAML.load(date.to_yaml)
  end

  def assert_datetimes
    datetime = DateTime.new(2014, 3, 1, 12, 45, 15)
    loaded   = YAML.load(datetime.to_yaml)

    assert [DateTime, Time].include?(loaded.class), 'datetime class'
    assert_equal datetime, loaded.to_datetime
    assert_equal datetime.to_time, loaded.to_time
  end

  def assert_datetimes_with_zones
    bst_datetime = DateTime.new(2014, 4, 1, 0, 0, 0, '+1')
    bst_loaded   = load_yaml(bst_datetime.to_yaml)

    assert [DateTime, Time].include?(bst_loaded.class), 'bst datetime class'
    assert_equal bst_datetime, bst_loaded.to_datetime
    assert_equal bst_datetime.to_time, bst_loaded.to_time

    gmt_datetime = DateTime.new(2014, 3, 1, 0, 0, 0, '+0')
    gmt_loaded   = load_yaml(gmt_datetime.to_yaml)

    assert [DateTime, Time].include?(gmt_loaded.class), 'gmt datetime class'
    assert_equal gmt_datetime, gmt_loaded.to_datetime
    assert_equal gmt_datetime.to_time, gmt_loaded.to_time
  end

  def assert_syck_1_8_yaml_loads_correctly
    yaml = "--- \nname: Dr. Doctor\000\000\000 \ndiagnosis: \"CIN 1 \\xE2\\x80\\x93 CIN 2\"\n"
    hash = load_yaml(yaml)

    # The null chars should be escaped:
    assert_equal 'Dr. Doctor0x000x000x00', hash['name']

    # The dash should be 3 bytes, but recognised as one char:
    assert_equal 15, hash['diagnosis'].bytes.to_a.length

    assert_syck_1_8_handles_encoding(hash)
  end

  def assert_syck_1_8_handles_encoding(hash)
    assert_equal 13, hash['diagnosis'].chars.to_a.length

    assert_equal 'UTF-8', hash['diagnosis'].encoding.name
    assert hash['diagnosis'].valid_encoding?
  end

  def assert_yaml_coercion_behaviour
    # UTF-8, with an unmappable byte too:
    yaml = "---\nfulltextreport: \"Here is \\xE2\\x80\\x93 a weird \\x9D char\"\n"

    # By default, we'd expect the (serialised) \x9D
    assert_raises(UTF8Encoding::UTF8CoercionError) { load_yaml(yaml) }

    # With the optional second argument, we can force an escape:
    hash = load_yaml(yaml, true)
    assert_equal 'Here is – a weird 0x9d char', hash['fulltextreport']
    assert_equal 'UTF-8', hash['fulltextreport'].encoding.name
  end
end
