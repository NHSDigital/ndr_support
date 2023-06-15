require 'active_record'
require 'active_support/time'

class Ourdate
  # Construct a daylight saving time safe datetime, with arguments
  #--
  # FIXME: Note that the arguments should be numbers, not strings -- it works
  # with strings arguments only after the 1970 epoch; before, it returns nil.
  #++
  def self.build_datetime(year, month = 1, day = 1, hour = 0, min = 0, sec = 0, usec = 0)
    return nil if year.nil?

    default_timezone = if ActiveRecord.respond_to?(:default_timezone)
                         ActiveRecord.default_timezone
                       else
                         ActiveRecord::Base.default_timezone # Rails <= 6.1
                       end
    if default_timezone == :local
      # Time.local_time(year, month, day, hour, min, sec, usec).to_datetime
      # Behave like oracle_adapter.rb
      seconds = sec + Rational(usec, 10**6)
      time_array = [year, month, day, hour, min, seconds]
      begin
        #--
        # TODO: Fails unit tests unless we .to_datetime here
        #       but the risk is we lose the usec component unnecesssarily.
        #       Investigate removing .to_datetime below.
        #++
        Time.send(default_timezone, *time_array).to_datetime
      rescue
        zone_offset = default_timezone == :local ? DateTime.now.offset : 0
        # Append zero calendar reform start to account for dates skipped by calendar reform
        DateTime.new(*time_array[0..5] << zone_offset << 0) rescue nil
      end
    else
      # Only supports fake GMT time -- needs improvement
      # Maybe use Time.zone.local or Time.local_time(year, month, day)
      Time.utc(year, month, day, hour, min, sec, usec).to_datetime
    end
  end
end
