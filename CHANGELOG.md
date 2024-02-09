## [Unreleased]
* No unreleased changes

## 5.10.2 / 2024-02-09
## Fixed
* Refactored the cleaning code to fix Rubcocop issues

## Added
* Added a new 'log10' cleaning method

## 5.10.1 / 2024-01-04
## Fixed
* Add 2026 bank holidays
* Allow YAML aliases when using `yaml_safe_classes`

## 5.10.0 / 2023-11-17
## Changed
* Generate UTF-8 encoded YAML by default. Disable with `utf8_storage = false`
* Use `YAML.safe_load` by default. Override with
  `self.yaml_safe_classes = yaml_safe_classes + [Klass1, Klass2]` and revert to
  unsafe loading with `yaml_safe_classes = :unsafe` and `gem 'psych', '< 4'`

## 5.9.7 / 2023-11-16
## Fixed
* YAMLSupport should preserve escaped backslashes in YAML text

## 5.9.6 / 2023-11-14
## Fixed
* YAMLSupport should preserve escape sequences in JSON text

## 5.9.5 / 2023-10-26
* Support Rails 7.1

## 5.9.4 / 2023-07-13
### Added
* Support Ruby 3.2. Drop support for Ruby 2.7, Rails 6.0

## 5.9.3 / 2022-12-02
## Fixed
* Support Rails 7.0

## Changed
* Drop support for Rails 5.2

## 5.9.2 / 2022-11-17
## Fixed
* Add extra 2023 Bank Holiday, and 2024 and 2025 Bank Holidays

## 5.9.1 / 2022-09-12
## Fixed
* Add extra 2022 Bank Holiday

## 5.9.0 / 2022-04-26
## Fixed
* Support Rails 6.1
* Support Ruby 3.1

## Changed
* Drop support for Ruby 2.6

## 5.8.4 / 2021-12-27
## Fixed
* Support 2023 public holidays

## 5.8.3 / 2021-11-25
## Fixed
* remove circular dependencies between Ourdate and Daterange

## 5.8.2 / 2021-10-11
## Fixed
* fix issue with blank date causing error for dateranges

## 5.8.1 / 2021-10-11
### Patched
* Added fix for failing threat scanner tests (#22)

## 5.8.0 / 2021-04-19
## Added
* Add ability to disable date reversing in Daterange

## Fixed
* Support Ruby 2.6-3.0.
* Fix ruby warnings

## 5.7.1 / 2021-01-03
## Fixed
* Postcodeize old Newport postcodes
* Bump rake version
* Support 2022 public holidays

## 5.7.0 / 2020-06-30
## Added
* Handle three char months in Daterange

## 5.6.1 / 2020-01-02
## Fixed
* Fix issue with 2020 public holiday
* Support 2021 public holidays
* Ensure dateranges up to 2030 are supported

## 5.6.0 / 2019-08-29
### Added
* Add `Integer#working_days_since`. (#11)

## 5.5.1 / 2019-05-15
### Fixed
* Support Ruby 2.6, Rails 6.0. Minimum Ruby/Rails versions are now 2.5/5.2
* Warn when WorkingDays lookup is getting stale
* Improved date parsing in `String#to_date`

## 5.5.0 / 2018-11-16
### Added
* Add `ThreatScanner` to wrap ClamAV for virus detection (#10)

### Fixed
* Added missing bank holidays for 2017-2019 (#9)

## 5.4.2 / 2018-08-06
### Fixed
* Fix Daterange equality comparisons

## 5.4.1 / 2018-07-09
### Fixed
* ensure Range#exclude? is available

## 5.4.0 / 2018-05-09
### Added
* Support Rails 5.2
