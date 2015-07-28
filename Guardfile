# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# directories %(app lib config test spec feature)
guard :rubocop, :all_on_start => false, :keep_failed => false do
  watch(%r{.+\.rb$})
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end

guard :minitest do
  watch(%r{^test/.+_test\.rb$})
  watch('test/test_helper.rb')  { 'test' }

  # Non-rails
  watch(%r{^lib/ndr_support/(.+)\.rb$}) { |m| "test/#{m[1]}_test.rb" }
end