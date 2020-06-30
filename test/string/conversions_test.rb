require 'test_helper'

class String::ConversionsTest < Minitest::Test
  test 'soundex' do
    assert_equal 'C460', 'colour'.soundex
    assert_equal 'color'.soundex, 'colour'.soundex
    assert 'color'.sounds_like('colour')
  end

  test 'date1' do
    assert_equal '01.01.2000', '2000'.date1.to_s
  end

  test 'date2' do
    assert_equal '31.12.2000', '2000'.date2.to_s
  end

  test 'thedate' do
    # Treating a String like Ourdate
    d = '01.03.2000'.thedate
    assert_kind_of Date, d
    assert_equal '01.03.2000', d.to_s

    assert_equal '03.04.2000', '03042000'.thedate.to_s
    assert_nil '01!02'.thedate, 'Expected illegal date format'
    assert_nil '2000'.thedate, 'Date ranges are illegal as single dates'
  end

  test 'thetime' do
    # Treating a local-format String like Ourtime (without seconds)
    t = '01.02.1993 04:05'.thetime
    assert_kind_of Time, t
    assert_equal '1993-02-01 04:05:00', t.strftime('%Y-%m-%d %H:%M:%S')
  end

  test 'surname_and_initials' do
    assert_equal 'Smith JD', 'SMITH JD'.surname_and_initials
    assert_equal 'Pencheon JM', 'PENCHEON JM'.surname_and_initials
  end

  test 'surnameize' do
    assert_equal 'Smith', 'SMITH'.surnameize
    assert_equal 'McKinnon', 'MCKINNON'.surnameize
    assert_equal 'O\'Neil', 'o\'neil'.surnameize
    assert_equal 'X', 'X'.surnameize
    assert_equal '', ''.surnameize
  end

  test 'nhs_numberize' do
    assert_equal '123 456 7890', '1234567890'.nhs_numberize
    assert_equal '012 345 6789', '0123456789'.nhs_numberize
    assert_equal '012345678', '012345678'.nhs_numberize
    assert_equal '', ''.nhs_numberize
  end

  test 'should parse dates correctly' do
    assert_ymd [2001, 3, 2],  '02.03.2001'.to_date
    assert_ymd [2001, 3, 2],  '02/03/2001'.to_date
    assert_ymd [2010, 7, 11], '2010-07-11'.to_date

    assert_ymd [2001, 3, 2],  '2.3.2001'.to_date
    assert_ymd [2001, 3, 2],  '2/3/2001'.to_date
    assert_ymd [2010, 7, 11], '2010-7-11'.to_date

    assert_ymd [2001, 2, 3], '2001/02/03'.to_date('yyyy/mm/dd')
    assert_ymd [2001, 2, 3], '2001/03/02'.to_date('yyyy/dd/mm')
    assert_ymd [2001, 2, 3], '2001-02-03'.to_date('yyyy-mm-dd')
    assert_ymd [2001, 2, 3], '03/02/2001'.to_date('dd/mm/yyyy')
    assert_ymd [2001, 2, 3], '02/03/2001'.to_date('mm/dd/yyyy')

    assert_ymd [2001, 2, 3],  '03-02-2001'.to_date('dd-mm-yyyy')
    assert_ymd [1976, 9, 23], '23-09-1976'.to_date('dd-mm-yyyy')

    assert_ymd [2001, 2, 3], '20010203'.to_date

    assert_ymd [1954, 2, 3], '03/02/54'.to_date
    assert_ymd [2014, 2, 3], '03/02/14'.to_date
    assert_ymd [2014, 2, 3], '03/FEB/14'.to_date

    assert_ymd [2014, 2, 3], '03-02-2014 00:00:00'.to_date
    assert_ymd [2014, 2, 3], '2014-02-03 00:00:00'.to_date
    assert_ymd [2014, 3, 2], '2014/03/02 13:02:01'.to_date
  end

  test 'should convert strings to DateTime correctly' do
    assert_equal 0, '2018-01-02'.to_datetime.utc_offset
    return unless ActiveRecord::Base.default_timezone == :local
    assert_equal Time.new(2017, 9, 2).utc_offset, '2017-09-02'.to_datetime.utc_offset, 'Expect consistent offset'
  end

  test 'ParseDate should behave consistently' do
    # We use ParseDate (and thus Date._parse) for
    # converting strings to dates. Its behaviour
    # has been known to change...
    #
    # Using '.' as a separator rather than '/' appears
    # to be more reliable across Ruby versions, and
    # as that is what we use internally, that is all
    # that we need to test here:

    # Behaves as you might hope:
    assert_ymd_parsed [2001, 2, 3], ParseDate.parsedate('20010203')
    assert_ymd_parsed [2001, 2, 3], ParseDate.parsedate('03.02.2001')

    # Doesn't behave as you might hope, but reliably gets day and year mixed:
    assert_ymd_parsed [3, 2, 14], ParseDate.parsedate('03.02.14')
    assert_ymd_parsed [3, 2, 54], ParseDate.parsedate('03.02.54')
    assert_ymd_parsed [3, 11, 4], ParseDate.parsedate('03.11.04')

    # Doesn't behave as you might hope, but reliably gets month and year mixed:
    assert_ymd_parsed [14, 2, 3], ParseDate.parsedate('03.FEB.14')
    assert_ymd_parsed [54, 2, 3], ParseDate.parsedate('03.FEB.54')
    assert_ymd_parsed [4, 2, 3],  ParseDate.parsedate('03.FEB.04')
  end

  test 'should calculate date differences / ages correctly' do
    [['03.02.1976', '11.11.2011', 35],
     ['29.02.1976', '28.02.2011', 35],
     ['28.02.1976', '28.02.2011', 35],
     ['28.02.1976', '27.02.2011', 34],
     ['01.03.1976', '28.02.2011', 34]
    ].each do |date1, date2, expected_diff|
      date1 = date1.to_date if date1.is_a?(String)
      date2 = date2.to_date if date2.is_a?(String)
      assert_equal(expected_diff,
                   Ourdate.date_difference_in_years(date2, date1),
                   "Expected difference between #{date2} and #{date1} to be #{expected_diff} years"
                   )
    end
  end

  # to_date(pattern = nil)
  test 'dd/mm/yyyy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13/02/1945'.to_date('dd/mm/yyyy')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03/05/1945'.to_date('dd/mm/yyyy')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13/02/1998'.to_date('dd/mm/yyyy')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03/05/1998'.to_date('dd/mm/yyyy')

    # reverse pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13/02/1945'.to_date('yyyy/mm/dd')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03/05/1945'.to_date('yyyy/mm/dd')
    # reverse post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13/02/1998'.to_date('yyyy/mm/dd')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03/05/1998'.to_date('yyyy/mm/dd')
  end

  test 'yyyy/mm/dd string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '1945/02/13'.to_date('yyyy/mm/dd')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '1945/05/03'.to_date('yyyy/mm/dd')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '1998/02/13'.to_date('yyyy/mm/dd')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '1998/05/03'.to_date('yyyy/mm/dd')

    # reverse pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '1945/02/13'.to_date('dd/mm/yyyy')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '1945/05/03'.to_date('dd/mm/yyyy')
    # reverse post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '1998/02/13'.to_date('dd/mm/yyyy')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '1998/05/03'.to_date('dd/mm/yyyy')
  end

  test 'yyyymmdd string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '19450213'.to_date('yyyymmdd')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '19450503'.to_date('yyyymmdd')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '19980213'.to_date('yyyymmdd')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '19980503'.to_date('yyyymmdd')

    # long pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '19450213SOMETHING'.to_date('yyyymmdd')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '19450503SOMETHING'.to_date('yyyymmdd')
    # long post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '19980213SOMETHING'.to_date('yyyymmdd')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '19980503SOMETHING'.to_date('yyyymmdd')

    # ONS wildcard date formats
    # (cannot convert to a Date, but need to parse into EBaseRecord date fields)
    assert_nil '19450000'.to_date('yyyymmdd')
    assert_nil '19450300'.to_date('yyyymmdd')
    assert_nil '19450013'.to_date('yyyymmdd')

    # parse our own date format correctly, regardless of format specification
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13.02.1998'.to_date('yyyymmdd')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03.05.1998'.to_date('yyyymmdd')
  end

  test 'ddmmyyyy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13021945'.to_date('ddmmyyyy')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03051945'.to_date('ddmmyyyy')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13021998'.to_date('ddmmyyyy')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03051998'.to_date('ddmmyyyy')

    # long pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13021945SOMETHING'.to_date('ddmmyyyy')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03051945SOMETHING'.to_date('ddmmyyyy')
    # long post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13021998SOMETHING'.to_date('ddmmyyyy')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03051998SOMETHING'.to_date('ddmmyyyy')
  end

  test 'mm/dd/yyyy string to_date' do
    # This is currently unsupported, but will be tested if implemented
    begin
      # pre_epoch
      assert_equal Ourdate.build_datetime(1945, 02, 13), '02/13/1945'.to_date('mm/dd/yyyy')
      assert_equal Ourdate.build_datetime(1945, 05, 03), '05/03/1945'.to_date('mm/dd/yyyy')
      # post epoch
      assert_equal Ourdate.build_datetime(1998, 02, 13), '02/13/1998'.to_date('mm/dd/yyyy')
      assert_equal Ourdate.build_datetime(1998, 05, 03), '05/03/1998'.to_date('mm/dd/yyyy')
    rescue RuntimeError => e
      raise e unless e.message == 'Unsupported date format'
    end
  end

  test 'yyyy-mm-dd string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '1945-02-13'.to_date('yyyy-mm-dd')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '1945-05-03'.to_date('yyyy-mm-dd')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '1998-02-13'.to_date('yyyy-mm-dd')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '1998-05-03'.to_date('yyyy-mm-dd')
  end

  test 'dd-mm-yyyy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13-02-1945'.to_date('dd-mm-yyyy')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03-05-1945'.to_date('dd-mm-yyyy')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13-02-1998'.to_date('dd-mm-yyyy')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03-05-1998'.to_date('dd-mm-yyyy')
  end

  test '%Y-%m-%d string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '1945-02-13'.to_date('%Y-%m-%d')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '1945-05-03'.to_date('%Y-%m-%d')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '1998-02-13'.to_date('%Y-%m-%d')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '1998-05-03'.to_date('%Y-%m-%d')

    assert_nil ''.to_date('%Y-%m-%d') # Should behave like Rails-defined to_date
    assert_nil '  '.to_date('%Y-%m-%d')
  end

  test '%d-%m-%Y string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13-02-1945'.to_date('%d-%m-%Y')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03-05-1945'.to_date('%d-%m-%Y')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13-02-1998'.to_date('%d-%m-%Y')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03-05-1998'.to_date('%d-%m-%Y')
  end

  test '%Y %b %d string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '1945 Feb 13'.to_date('%Y %b %d')
    assert_equal Ourdate.build_datetime(1945, 05, 03), '1945 May 03'.to_date('%Y %b %d')
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '1998 Feb 13'.to_date('%Y %b %d')
    assert_equal Ourdate.build_datetime(1998, 05, 03), '1998 May 03'.to_date('%Y %b %d')
  end

  test 'inferred yyyy-mm-dd string to_date' do
    # pattern pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '1945-02-13'.to_date
    assert_equal Ourdate.build_datetime(1945, 05, 03), '1945-05-03 00:00:00'.to_date
    # pattern post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '1998-02-13 00:00:00'.to_date
    assert_equal Ourdate.build_datetime(1998, 05, 03), '1998-05-03'.to_date
  end

  test 'inferred dd-mm-yyyy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13-02-1945'.to_date
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03-05-1945 00:00:00'.to_date
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13-02-1998 00:00:00'.to_date
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03-05-1998'.to_date
  end

  test 'inferred dd.mm.yyyy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13.02.1945'.to_date
    assert_equal Ourdate.build_datetime(1945, 05, 03), '3.5.1945'.to_date
    # post epoch
    assert_equal Ourdate.build_datetime(1998, 02, 13), '13.2.1998'.to_date
    assert_equal Ourdate.build_datetime(1998, 05, 03), '03.05.1998'.to_date
  end

  test 'inferred yyyymmdd string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '19450213'.to_date
    assert_equal Ourdate.build_datetime(1945, 05, 03), '19450503'.to_date
    # post epoch
    assert_equal Ourdate.build_datetime(2008, 02, 13), '20080213'.to_date
    assert_equal Ourdate.build_datetime(2008, 05, 03), '20080503'.to_date
  end

  test 'inferred dd/mm/yy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13/02/45'.to_date
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03/05/45'.to_date
    # post epoch
    assert_equal Ourdate.build_datetime(2008, 02, 13), '13/02/08'.to_date
    assert_equal Ourdate.build_datetime(2008, 05, 03), '03/05/08'.to_date
  end

  test 'inferred dd/mon/yy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13/FEB/45'.to_date
    assert_equal Ourdate.build_datetime(1945, 06, 03), '03/JUN/45'.to_date
    # post epoch
    assert_equal Ourdate.build_datetime(2008, 02, 13), '13/FEB/08'.to_date
    assert_equal Ourdate.build_datetime(2008, 06, 03), '03/JUN/08'.to_date
  end

  test 'inferred dd/mm/yyyy string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13/02/1945'.to_date
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03/05/1945'.to_date
    # post epoch
    assert_equal Ourdate.build_datetime(2008, 02, 13), '13/02/2008'.to_date
    assert_equal Ourdate.build_datetime(2008, 05, 03), '03/05/2008'.to_date
  end

  test 'inferred dd/mm/yyyy hh:mm string to_date' do
    # pre_epoch
    assert_equal Ourdate.build_datetime(1945, 02, 13), '13/02/1945 13:38'.to_date
    assert_equal Ourdate.build_datetime(1945, 05, 03), '03/05/1945 13:38'.to_date
    # post epoch
    assert_equal Ourdate.build_datetime(2008, 02, 13), '13/02/2008 13:38'.to_date
    assert_equal Ourdate.build_datetime(2008, 05, 03), '03/05/2008 13:38'.to_date
  end

  test 'incorrectly formatted string to_date' do
    assert_nil '10-1975'.to_date
    assert_nil '10.1975A'.to_date
    assert_nil '10.1975AA'.to_date
  end

  test 'to_boolean' do
    assert_equal true, 'true'.to_boolean
    assert_equal true, 'yes'.to_boolean
    assert_equal true, '1'.to_boolean
    assert_equal false, 'false'.to_boolean
    assert_equal false, 'no'.to_boolean
    assert_equal false, '0'.to_boolean
    assert_raises ArgumentError do
      'meaningless'.to_boolean
    end
  end

  def assert_ymd(ymd, date)
    assert_equal ymd.first,  date.year,  'years were not equal'
    assert_equal ymd.second, date.month, 'months were not equal'
    assert_equal ymd.third,  date.day,   'days were not equal'
  end

  def assert_ymd_parsed(ymd, parse_results)
    y, m, d, *_ = parse_results
    assert_equal ymd, [y, m, d]
  end
end
