# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# This group allows to skip running rubocop when tests fail.
group :red_green_refactor, halt_on_fail: true do
  guard :minitest do
    watch(%r{^test/.+_test\.rb$})
    watch('test/test_helper.rb')  { 'test' }

    # Non-rails
    watch(%r{^lib/ndr_support/(.+)\.rb$}) { |m| "test/#{m[1]}_test.rb" }
  end

  # automatically check Ruby code style with Rubocop when files are modified
  guard :shell do
    watch(/.+\.(rb|rake)$/) do |m|
      unless system("bundle exec rake rubocop:diff #{m[0]}")
        Notifier.notify "#{File.basename(m[0])} inspected, offenses detected",
                        title: 'RuboCop results (partial)', image: :failed
      end
      nil
    end
  end
end
