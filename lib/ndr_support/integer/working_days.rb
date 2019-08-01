# Mixin for working_days
class Integer
  # Returns a date of the number of working days since a given date
  def working_days_since(date)
    times do
      date = date.next
      date = date.next while date.public_holiday? || !date.weekday?
    end
    date
  end
end
