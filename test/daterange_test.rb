require 'test_helper'

class DaterangeTest < ActiveSupport::TestCase
  def test_Daterange
    # basic creation:
    dr = Daterange.new
    assert_equal '', dr.to_s
    assert_nil dr.date1
    assert_nil dr.date2
    assert dr.empty?
    assert dr.blank?  # delegates to dr.empty?
    # creation from dates:
    d = Date::today
    dr = Daterange.new d, d
    assert_nil dr.source
    assert_not_nil dr.date1
    assert_not_nil dr.date2
    assert !dr.empty?
    assert_equal d.to_s, dr.to_s # because just one day
    assert_match(/\d\d\.\d\d\.\d\d\d\d/, dr.to_s) # default format
    dr = Daterange.new d, d+1
    assert_match(/\d\d\.\d\d\.\d\d\d\d to \d\d.\d\d.\d\d\d\d/, dr.to_s)
    # dates in reverse order
    dr2 = Daterange.new d+1, d
    assert_equal(dr.to_s, dr2.to_s)
    # illegal strings
    dr = Daterange.new('01/o1/2000')
    assert_equal '', dr.to_s
    assert_nil dr.date1
    assert_nil dr.date2
    assert !dr.empty?  # Illegal dates do not count as empty / blank,
    assert_not_nil dr.source # but the illegal string is preserved
    # out of range
    dr = Daterange.new('31/12/1879')
    assert_equal '', dr.to_s
    assert_nil dr.date1
    assert_nil dr.date2
    # all attributes:
    dr = Daterange.new('2000')
    assert_equal '2000', dr.source
    assert_equal '2000', dr.to_s
    assert_equal '01.01.2000', dr.date1.to_s
    assert_equal '31.12.2000', dr.date2.to_s
    dr = Daterange.new('1880 2020')
    assert_equal '01.01.1880 to 31.12.2020', dr.to_s
    assert_equal '01.01.1880', dr.date1.to_s
    assert_equal '31.12.2020', dr.date2.to_s
    assert_equal '1880 2020', dr.source
    # all input styles:
    dr = Daterange.new('2000-05')
    assert_equal '05.2000', dr.to_s
    dr = Daterange.new('06.2000')
    assert_equal '01.06.2000', dr.date1.to_s
    assert_equal '30.06.2000', dr.date2.to_s
    assert_equal '06.2000', dr.to_s
    dr = Daterange.new('07/2000')
    assert_equal '07.2000', dr.to_s
    assert_equal '01.07.2000', dr.date1.to_s
    assert_equal '31.07.2000', dr.date2.to_s
    dr = Daterange.new('082000')
    assert_equal '08.2000', dr.to_s
    assert_equal '01.08.2000', dr.date1.to_s
    assert_equal '31.08.2000', dr.date2.to_s
    dr = Daterange.new('01.05.2000 to 31.05.2000')
    assert_equal '05.2000', dr.to_s
    assert_equal '01.05.2000', dr.date1.to_s
    assert_equal '31.05.2000', dr.date2.to_s
    dr = Daterange.new('2000 TO 2001')
    assert_equal '01.01.2000 to 31.12.2001', dr.to_s
    dr = Daterange.new('2000-09-12')
    assert_equal '12.09.2000', dr.to_s
    dr = Daterange.new('13/09/2000')
    assert_equal '13.09.2000', dr.to_s
    dr = Daterange.new('14.09.2000')
    assert_equal '14.09.2000', dr.to_s
    dr = Daterange.new('15092000')
    assert_equal '15.09.2000', dr.to_s
    dr = Daterange.new('03.2010') # Span time zones (daylight saving)
    assert_equal '03.2010', dr.to_s # Ideally '03.2010'

    dr1 = Daterange.new('2001')
    dr2 = Daterange.new('2002')
    deny dr1.intersects?(dr2)
    deny dr2.intersects?(dr1)

    dr1 = Daterange.new('2001')
    dr2 = Daterange.new('2001')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)

    dr1 = Daterange.new('2001 to 2003')
    dr2 = Daterange.new('2002 to 2004')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)

    dr1 = Daterange.new('01.05.2000 to 31.05.2000')
    dr2 = Daterange.new('02.05.2000 to 30.05.2000')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)

    dr1 = Daterange.new('01.05.2000 to 31.05.2000')
    dr2 = Daterange.new('01.04.2000 to 01.05.2000')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)

    dr1 = Daterange.new('01.05.2000 to 31.05.2000')
    dr2 = Daterange.new('31.05.2000 to 01.06.2000')
    assert dr1.intersects?(dr2)
    assert dr2.intersects?(dr1)

    dr1 = Daterange.new('02.05.2000 to 31.05.2000')
    dr2 = Daterange.new('01.04.2000 to 01.05.2000')
    deny dr1.intersects?(dr2)
    deny dr2.intersects?(dr1)

    dr1 = Daterange.new
    dr2 = Daterange.new('01.04.2000 to 01.05.2000')
    deny dr1.intersects?(dr2)
    deny dr2.intersects?(dr1)

    dr1 = Daterange.new('01.04.2000 to 01.05.2000')
    dr2 = Daterange.new
    deny dr1.intersects?(dr2)
    deny dr2.intersects?(dr1)

    dr1 = Daterange.new
    dr2 = Daterange.new
    deny dr1.intersects?(dr2)
    deny dr2.intersects?(dr1)

    dr = Daterange.merge('2001, 30.04.2005, 2003,,')
    assert_equal '01.01.2001 to 30.04.2005', dr.to_s
  end
end
