require 'active_support/time'
require 'ndr_support/ourdate'

# Convert a string into a time value (timestamp)
# (helped by String.thetime)
class Ourtime
  attr_reader :thetime

  # TODO: deprecate this...
  def initialize(x = nil)
    if x.is_a?(Time)
      @thetime = x
    elsif x.is_a?(Date)
      @thetime = x.to_time
    elsif x.is_a?(String)
      self.source = x
    else
      @thetime = nil
    end
  end

  def to_s
    @thetime ? @thetime.to_time.to_s(:ui) : ''
  end

  def empty?
    # An unspecified time will be empty. A valid or invalid time will not.
    @thetime.nil? && @source.blank?
  end

  def source=(s)
    begin
      # Re-parse our own timestamps [+- seconds] without swapping month / day
      @thetime = Time.strptime(s, '%d.%m.%Y %H:%M:%S')
    rescue ArgumentError
      begin
        @thetime = Time.strptime(s, '%d.%m.%Y %H:%M')
      rescue ArgumentError
        @thetime = Time.parse(s)
      end
    end
  end

  private :source=
end
