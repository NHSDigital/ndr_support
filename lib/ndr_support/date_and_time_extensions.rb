require 'yaml'

require File.expand_path('../concerns/working_days', __FILE__)
[Time, Date, DateTime].each { |klass| klass.send(:include, WorkingDays) }

class Date
  # Note: default date format is specified in config/environment.rb
  def to_verbose
    strftime('%d %B %Y')
  end # our long format

  # to_iso output must be SQL safe for security reasons
  def to_iso
    strftime('%Y-%m-%d')
  end # ISO date format

  def to_ours
    to_s
  end

  def to_YYYYMMDD # convert dates into format 'YYYYMMDD' - used in tracing
    self.year.to_s + self.month.to_s.rjust(2, '0') + self.day.to_s.rjust(2, '0')
  end
end

#-------------------------------------------------------------------------------

class Time
  def to_ours
    strftime('%d.%m.%Y %H:%M')
  end # Show times in our format

  # to_iso output must be SQL safe for security reasons
  def to_iso
    strftime('%Y-%m-%dT%H:%M:%S')
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
      # With YAML's crazy engine switching, it seems we
      # can't rely including a module to define this method:
      Date.module_eval do
        def to_yaml(opts = {})
          ::YAML.quick_emit(object_id, opts) do |out|
            out.scalar('tag:yaml.org,2002:timestamp', to_s(:yaml), :plain)
          end
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

# Maintain API:
NdrSupport.attempt_date_patch!
