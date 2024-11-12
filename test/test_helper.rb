require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'minitest/unit'
require 'mocha/minitest'

require 'active_record'
require 'active_support/time'
require 'ndr_support'
require 'tmpdir'

NdrSupport.apply_era_date_formats!

# We do not use Rails' preferred time zone support, as this would
# require all dates to be stored in UTC in the database.
# Thus a birth date of 1975-06-01 would be stored as 1975-05-31 23.00.00.
# Instead, we want to store all times in local time.
ActiveRecord.default_timezone = :local
ActiveRecord::Base.time_zone_aware_attributes = false
Time.zone = 'London'

SafePath.configure! File.dirname(__FILE__) + '/resources/filesystem_paths.yml'

# Borrowed from ActiveSupport::TestCase
module Minitest
  class Test
    # Allow declarive test syntax:
    def self.test(name, &block)
      test_name = "test_#{name.gsub(/\s+/, '_')}".to_sym
      defined = method_defined? test_name
      fail "#{test_name} is already defined in #{self}" if defined
      if block_given?
        define_method(test_name, &block)
      else
        define_method(test_name) do
          flunk "No implementation provided for #{name}"
        end
      end
    end
  end
end
