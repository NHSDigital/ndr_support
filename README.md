# NdrSupport [![Build Status](https://travis-ci.org/PublicHealthEngland/ndr_support.svg?branch=master)](https://travis-ci.org/PublicHealthEngland/ndr_support)

This is the Public Health England (PHE) National Disease Registers (NDR) Support ruby gem, providing:

1. core ruby class extensions;
2. additional time, regular expression, file security and encoding classes; and
3. rake tasks to manage code auditing of ruby based projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ndr_support', :git => 'https://github.com/PublicHealthEngland/ndr_support.git'
```

And then execute:

    $ bundle

Or install it yourself by cloning the project, then executing:

    $ gem install ndr_support.gem

## Usage

ndr_support extends/overrides the following core classes/modules:

- Array
- Fixnum
- Hash
- Integer
- NilClass
- String
- Time

ndr_support adds the following classes:

- Daterange
- Ourdate
- Ourtime
- RegexpRange
- SafeFile
- SafePath
- UTF8Encoding

### YAML Serialization Wrapper

ndr_support also provides a lightweight wrapper around YAML serialization to provide support for YAML engines and string encodings. This behavour is not enabled by default.

To enable this add the following line to your code:

```ruby
include NdrSupport::YAML::SerializationMigration
```

### Code Auditing Rake Tasks

ndr_support also provides a mechanism to manage the state of routine code quality and security peer reviews. It should be used as part of wider quality and security policies.

It provides rake tasks to help manage the process of persisting the state of security reviews.

Once files have been reviewed as secure, the revision number for that file is stored in code_safety.yml. If used within a Rails app, this file is stored in the config/ folder, otherwise it is kept in the project's root folder.

Note: This feature currently only supports a subversion repository, either by using svn directly or through git svn.

To add code auditing to your project add this line to your application's Rakefile:

```ruby
require 'ndr_support/tasks'
```

For more details of the tasks available, execute:

    $ rake -T audit

## Contributing

1. Fork it ( https://github.com/PublicHealthEngland/ndr_support/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

## Test Data

All test data in this repository is fictitious. Any resemblance to real persons, living or dead, is purely coincidental.

Note: Real codes exist in the tests, postcodes for example, but bear no relation to real patient data. Please ensure that you *always* only ever commit dummy data when contributing to this project.
