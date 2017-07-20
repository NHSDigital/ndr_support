require 'active_support/time'
require 'ndr_support/ourdate'

# Convert a string into a time value (timestamp)
# (helped by String.thetime)
class Ourtime
  attr_reader :thetime

  def self.zone
    @zone ||= ActiveSupport::TimeZone.new('London')
  end

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

  private

  def source=(s)
    @thetime = zone.parse(s)
  end

  def zone
    # `delegate` doesn't work for this on Rails 3.2
    self.class.zone
  end
end
