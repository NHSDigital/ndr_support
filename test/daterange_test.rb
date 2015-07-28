require 'test_helper'

# This tests our Daterange class
class DaterangeTest < Minitest::Test
  def test_basic_creation
    dr = Daterange.new
    assert_equal '', dr.to_s
    assert_nil dr.date1
    assert_nil dr.date2
    assert dr.empty?
    assert dr.blank?  # delegates to dr.empty?
  end

  def test_creation_from_dates
    d = Date.today
    dr = Daterange.new d, d
    assert_nil dr.source
    refute_nil dr.date1
    refute_nil dr.date2
    refute dr.empty?
    assert_equal d.to_s, dr.to_s # because just one day
    # assert_match(/\d\d\.\d\d\.\d\d\d\d/, dr.to_s) # default format
    # dr = Daterange.new d, d + 1
    # assert_match(/\d\d\.\d\d\.\d\d\d\d to \d\d.\d\d.\d\d\d\d/, dr.to_s)
  end

  def test_dates_in_reverse_order
    d = Date.today
    dr = Daterange.new d, d + 1
    dr2 = Daterange.new d + 1, d
    assert_equal(dr.to_s, dr2.to_s)
  end

  def test_illegal_strings
    dr = Daterange.new('01/o1/2000')
    assert_equal '', dr.to_s
    assert_nil dr.date1
    assert_nil dr.date2
    refute dr.empty?  # Illegal dates do not count as empty / blank,
    refute_nil dr.source # but the illegal string is preserved
  end

  def test_out_of_range
    dr = Daterange.new('31/12/1879')
    assert_equal '', dr.to_s
    assert_nil dr.date1
    assert_nil dr.date2
  end

  def test_year_attributes
    dr = Daterange.new('2000')
    assert_equal '2000', dr.source
    assert_equal '2000', dr.to_s
    assert_equal '01.01.2000', dr.date1.to_s
    assert_equal '31.12.2000', dr.date2.to_s
  end

  def test_year_range_attributes
    dr = Daterange.new('1880 2020')
    assert_equal '01.01.1880 to 31.12.2020', dr.to_s
    assert_equal '01.01.1880', dr.date1.to_s
    assert_equal '31.12.2020', dr.date2.to_s
    assert_equal '1880 2020', dr.source
  end

  def test_hyphen_month_input_style
    dr = Daterange.new('2000-05')
    assert_equal '05.2000', dr.to_s
  end

  def test_dot_month_input_style
    dr = Daterange.new('06.2000')
    assert_equal '01.06.2000', dr.date1.to_s
    assert_equal '30.06.2000', dr.date2.to_s
    assert_equal '06.2000', dr.to_s
  end

  def test_forwardslash_month_input_style
    dr = Daterange.new('07/2000')
    assert_equal '07.2000', dr.to_s
    assert_equal '01.07.2000', dr.date1.to_s
    assert_equal '31.07.2000', dr.date2.to_s
  end

  def test_noseparator_month_input_style
    dr = Daterange.new('082000')
    assert_equal '08.2000', dr.to_s
    assert_equal '01.08.2000', dr.date1.to_s
    assert_equal '31.08.2000', dr.date2.to_s
  end

  def test_date_to_date_input_style
    dr = Daterange.new('01.05.2000 to 31.05.2000')
    assert_equal '05.2000', dr.to_s
    assert_equal '01.05.2000', dr.date1.to_s
    assert_equal '31.05.2000', dr.date2.to_s
    dr = Daterange.new('2000 TO 2001')
    assert_equal '01.01.2000 to 31.12.2001', dr.to_s
  end

  def test_hyphen_date_input_style
    dr = Daterange.new('2000-09-12')
    assert_equal '12.09.2000', dr.to_s
  end

  def test_forwardslash_date_input_style
    dr = Daterange.new('13/09/2000')
    assert_equal '13.09.2000', dr.to_s
  end

  def test_dot_date_input_style
    dr = Daterange.new('14.09.2000')
    assert_equal '14.09.2000', dr.to_s
  end

  def test_noseparator_date_input_style
    dr = Daterange.new('15092000')
    assert_equal '15.09.2000', dr.to_s
  end

  def test_spen_daylight_saving
    dr = Daterange.new('03.2010') # Span time zones (daylight saving)
    assert_equal '03.2010', dr.to_s # Ideally '03.2010'
  end

  def test_year_intersection
    dr1 = Daterange.new('2001')
    dr2 = Daterange.new('2002')
    refute dr1.intersects?(dr2)
    refute dr2.intersects?(dr1)

    dr1 = Daterange.new('2001')
    dr2 = Daterange.new('2001')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)
  end

  def test_year_range_intersection
    dr1 = Daterange.new('2001 to 2003')
    dr2 = Daterange.new('2002 to 2004')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)
  end

  def test_subset_intersection
    dr1 = Daterange.new('01.05.2000 to 31.05.2000')
    dr2 = Daterange.new('02.05.2000 to 30.05.2000')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)
  end

  def test_smallest_inhabited_intersection
    dr1 = Daterange.new('01.05.2000 to 31.05.2000')
    dr2 = Daterange.new('01.04.2000 to 01.05.2000')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)

    dr1 = Daterange.new('01.05.2000 to 31.05.2000')
    dr2 = Daterange.new('31.05.2000 to 01.06.2000')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)
  end

  def test_disjointed_intersection
    dr1 = Daterange.new('02.05.2000 to 31.05.2000')
    dr2 = Daterange.new('01.04.2000 to 01.05.2000')
    refute dr1.intersects?(dr2)
    refute dr2.intersects?(dr1)
  end

  def test_real_empty_intersection
    dr1 = Daterange.new
    dr2 = Daterange.new('01.04.2000 to 01.05.2000')
    refute dr1.intersects?(dr2)
    refute dr2.intersects?(dr1)

    dr1 = Daterange.new('01.04.2000 to 01.05.2000')
    dr2 = Daterange.new
    refute dr1.intersects?(dr2)
    refute dr2.intersects?(dr1)
  end

  def test_empty_empty_intersection
    dr1 = Daterange.new
    dr2 = Daterange.new
    refute dr1.intersects?(dr2)
    refute dr2.intersects?(dr1)
  end

  def test_merge
    dr = Daterange.merge('2001, 30.04.2005, 2003,,')
    assert_equal '01.01.2001 to 30.04.2005', dr.to_s
  end
end
