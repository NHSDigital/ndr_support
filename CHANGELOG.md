## [Unreleased]
*no unreleased changes*

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
