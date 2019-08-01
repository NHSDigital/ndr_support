require 'date'
require 'ndr_support/concerns/working_days'
require 'ndr_support/integer/working_days'

[Time, Date, DateTime].each { |klass| klass.send(:include, WorkingDays) }
