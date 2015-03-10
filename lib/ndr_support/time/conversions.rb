class Time
  # Ruby 1.9 defines Time#to_time natively (as part of the
  # stdlib Time, rather than core Time), but it returns
  # the time in the local timezone. ActiveSupport contains
  # the following definition, but it is only actually used
  # by Ruby 1.8.7. We wish to continue with that behaviour,
  # as local time zones have caused problems with our
  # Time#to_s format (which either formats as '%d.%m.%Y %H:%M'
  # or '%d.%m.%Y').
  def to_time
    self
  end
end
