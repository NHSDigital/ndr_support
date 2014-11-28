# Extend Fixnum for use in our Daterange class
class Fixnum
  # Julian date number to Ruby Date
  def jd_to_date
    Date.jd(self)
  end

  def jd_to_datetime
    date = jd_to_date
    Ourdate.build_datetime(date.year, date.month, date.day)
  end
end
