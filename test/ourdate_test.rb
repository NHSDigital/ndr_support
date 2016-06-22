require 'test_helper'

# This tests our Ourdate class
class OurdateTest < Minitest::Test
  def test_date_and_time
    d = Ourdate.build_datetime(2003, 11, 30)
    assert_equal '2003-11-30', d.to_iso
    assert_equal '30.11.2003', d.to_s
  end

  def test_ourdate
    # Creating an Ourdate from a String
    od = Ourdate.new('01.02.2000')
    assert_equal Date.new(2000, 2, 1).to_s(:ui), od.to_s
    assert_kind_of Date, od.thedate
    assert_equal '01.02.2000', od.thedate.to_s
    # Creating an Ourdate from a Date
    od = Ourdate.new(Date.new(2000, 3, 1))
    assert_equal '01.03.2000', od.to_s
  end

  def test_blank
    assert Ourdate.new.blank?  # delegates to empty?
  end
end
