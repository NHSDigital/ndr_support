lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ndr_support/version'

Gem::Specification.new do |spec|
  spec.name          = 'ndr_support'
  spec.version       = NdrSupport::VERSION
  spec.authors       = ['NCRS Development Team']
  spec.email         = []
  spec.summary       = 'NDR Support library'
  spec.description   = 'Provides NDR classes and class extensions'
  spec.homepage      = 'https://github.com/PublicHealthEngland/ndr_support'
  spec.license       = 'MIT'

  gem_files          = %w[CHANGELOG.md CODE_OF_CONDUCT.md LICENSE.txt README.md
                          lib ndr_support.gemspec]
  spec.files         = `git ls-files -z`.split("\x0").
                       select { |f| gem_files.include?(f.split('/')[0]) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord',  '>= 7.0', '< 8.1'
  spec.add_dependency 'activesupport', '>= 7.0', '< 8.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '>= 12.3.3'

  spec.required_ruby_version = '>= 3.0'

  # Avoid std-lib minitest (which has different namespace)
  spec.add_development_dependency 'minitest', '>= 5.0.0'
  spec.add_development_dependency 'mocha', '~> 2.0'

  spec.add_development_dependency 'ndr_dev_support', '~> 7.0'

  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-shell'
  spec.add_development_dependency 'guard-minitest'
  spec.add_development_dependency 'terminal-notifier-guard' if RUBY_PLATFORM =~ /darwin/
  spec.add_development_dependency 'simplecov'
end
