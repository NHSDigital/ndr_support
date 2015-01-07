require 'test/unit'
require 'active_record'
require 'active_support/test_case'
require 'active_support/time'
require 'ndr_support'
require 'tmpdir'

NdrSupport.apply_era_date_formats!

# We do not use Rails' preferred time zone support, as this would
# require all dates to be stored in UTC in the database.
# Thus a birth date of 1975-06-01 would be stored as 1975-05-31 23.00.00.
# Instead, we want to store all times in local time.
ActiveRecord::Base.default_timezone = :local
ActiveRecord::Base.time_zone_aware_attributes = false

SafePath.configure! File.dirname(__FILE__) + '/resources/filesystem_paths.yml'

module ActiveSupport
  class TestCase
    # A useful helper to make 'assert !condition' statements more readable
    def deny(condition, message = 'No further information given')
      assert !condition, message
    end

    # Assert that two arrays have the same contents.
    #
    #  assert_same_elements [1,3,2], [3,2,1] #=> PASS
    #
    #  assert_same_elements [1,2], [1,2,3] #=> FAIL
    #
    #  assert_same_elements [], [] #=> PASS
    #
    #  assert_same_elements [1,1,1], [1,1] #=> FAIL
    #
    #  assert_same_elements [1,1,1], [1,1,1] #=> PASS
    #
    def assert_same_elements(array1, array2, *args)
      converter = proc do |array|
        {}.tap do |hash|
          array.each do |key|
            if hash.key?(key)
              key = [key] until !hash.key?(key)
            end
            hash[key] = true
          end
        end
      end

      condition = converter[array1] == converter[array2]
      assert condition,
             "#{array1.inspect} << EXPECTED NOT SAME AS ACTUAL >> #{array2.inspect}",
             *args
    end
  end
end
