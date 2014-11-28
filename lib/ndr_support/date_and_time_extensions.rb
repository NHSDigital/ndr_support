class Date
#	Note: default date format is specified in config/environment.rb
  def to_verbose() strftime('%d %B %Y') 	end # our long format
  # to_iso output must be SQL safe for security reasons
  def to_iso() strftime('%Y-%m-%d') end # ISO date format
  def to_ours() to_s end
  def to_YYYYMMDD # convert dates into format 'YYYYMMDD' - used in tracing
    self.year.to_s + self.month.to_s.rjust(2,"0") + self.day.to_s.rjust(2,"0")
  end
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.scalar( "tag:yaml.org,2002:timestamp", strftime('%Y-%m-%d'), :plain )
    end
  end
end

#-------------------------------------------------------------------------------

class Time
  def to_ours() strftime('%d.%m.%Y %H:%M') end # Show times in our format
  # to_iso output must be SQL safe for security reasons
  def to_iso() strftime('%Y-%m-%dT%H:%M:%S') end
end