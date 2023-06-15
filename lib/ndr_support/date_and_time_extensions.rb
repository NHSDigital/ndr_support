require 'yaml'
require 'date'
require 'ndr_support/working_days'

class Date
  # to_iso output must be SQL safe for security reasons
  def to_iso
    strftime('%Y-%m-%d')
  end # ISO date format

  alias orig_to_datetime to_datetime

  def to_datetime
    # Default timezone for Date is GMT, not local timezone
    default_timezone = if ActiveRecord.respond_to?(:default_timezone)
                         ActiveRecord.default_timezone
                       else
                         ActiveRecord::Base.default_timezone # Rails <= 6.1
                       end
    return in_time_zone.to_datetime if default_timezone == :local

    orig_to_datetime
  end

  alias orig_to_s to_s

  # Rails 7 stops overriding to_s (without a format specification) (for performance on Ruby 3.1)
  # cf. activesupport-7.0.4/lib/active_support/core_ext/date/deprecated_conversions.rb
  # We keep overriding this for compatibility
  def to_s(format = :default)
    if format == :default
      to_formatted_s(:default)
    else
      orig_to_s(format)
    end
  end
end

#-------------------------------------------------------------------------------

class Time
  # to_iso output must be SQL safe for security reasons
  def to_iso
    strftime('%Y-%m-%dT%H:%M:%S')
  end

  alias orig_to_s to_s

  # Rails 7 stops overriding to_s (without a format specification) (for performance on Ruby 3.1)
  # cf. activesupport-7.0.4/lib/active_support/core_ext/date/deprecated_conversions.rb
  # We keep overriding this for compatibility
  def to_s(format = :default)
    if format == :default
      to_formatted_s(:default)
    else
      orig_to_s(format)
    end
  end
end

#-------------------------------------------------------------------------------

class DateTime
  alias orig_to_s to_s

  # Rails 7 stops overriding to_s (without a format specification) (for performance on Ruby 3.1)
  # cf. activesupport-7.0.4/lib/active_support/core_ext/date/deprecated_conversions.rb
  # We keep overriding this for compatibility
  def to_s(format = :default)
    if format == :default
      to_formatted_s(:default)
    else
      orig_to_s(format)
    end
  end
end

#-------------------------------------------------------------------------------

module ActiveSupport
  class TimeWithZone
    alias orig_to_s to_s

    # Rails 7 stops overriding to_s (without a format specification) (for performance on Ruby 3.1)
    # cf. activesupport-7.0.4/lib/active_support/core_ext/date/deprecated_conversions.rb
    # We keep overriding this for compatibility
    def to_s(format = :default)
      if format == :default
        to_formatted_s(:default)
      else
        orig_to_s(format)
      end
    end
  end
end

#-------------------------------------------------------------------------------

module NdrSupport
  class << self
    # Within the NDR, we change default date formatting, as below.
    # This can cause problems with YAML emitted by syck, so we have to
    # patch Date#to_yaml too.
    def apply_era_date_formats!
      update_date_formats!
      update_time_formats!

      attempt_date_patch!
    end

    def attempt_date_patch!
      # There are potential load order issues with this patch,
      # as it needs to be applied once syck has loaded.
      fail('Date#to_yaml must exist to be patched!') unless Date.respond_to?(:to_yaml)
      apply_date_patch!
    end

    private

    def apply_date_patch!
      # Ensure we emit "yaml-formatted" string, instead of the revised default format.
      Psych::Visitors::YAMLTree.class_eval do
        def visit_Date(o)
          @emitter.scalar o.to_formatted_s(:yaml), nil, nil, true, false, Psych::Nodes::Scalar::ANY
        end
      end
    end

    # Override default date and time formats:
    def update_date_formats!
      Date::DATE_FORMATS.update(
        :db      => '%Y-%m-%d %H:%M:%S',
        :ui      => '%d.%m.%Y',
        :yaml    => '%Y-%m-%d', # For Dates
        :default => '%d.%m.%Y'
      )
    end

    # Rails 2 loads Oracle dates (with timestamps) as DateTime or Time values
    # (before or after 1970) whereas Rails 1.2 treated them as Date objects.
    # Therefore we have a formatting challenge, which we overcome by hiding
    # the time if it's exactly midnight
    def update_time_formats!
      Time::DATE_FORMATS.update(
        :db      => '%Y-%m-%d %H:%M:%S',
        :ui      => '%d.%m.%Y %H:%M',
        :yaml    => '%Y-%m-%d %H:%M:%S %:z', # For DateTimes
        :default => lambda do |time|
          non_zero_time = time.hour != 0 || time.min != 0 || time.sec != 0
          time.strftime(non_zero_time ? '%d.%m.%Y %H:%M' : '%d.%m.%Y')
        end
      )
    end
  end
end
