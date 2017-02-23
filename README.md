# NdrSupport [![Build Status](https://travis-ci.org/PublicHealthEngland/ndr_support.svg?branch=master)](https://travis-ci.org/PublicHealthEngland/ndr_support) [![Gem Version](https://badge.fury.io/rb/ndr_support.svg)](https://badge.fury.io/rb/ndr_support)

This is the Public Health England (PHE) National Disease Registers (NDR) Support ruby gem, providing:

1. core ruby class extensions;
2. additional time, regular expression, file security, password checking/generation, and encoding classes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ndr_support'
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
- NdrSupport::Password
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
