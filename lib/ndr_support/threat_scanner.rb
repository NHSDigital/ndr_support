require 'English'
require 'shellwords'

# Runs a virus/malware check against the given path, using ClamAV.
#
# Sample usage:
#
#   # Call with a file object:
#   ThreatScanner.new(@unknown_tempfile).check!
#
#   # ...or with a path:
#   ThreatScanner.new('path/to/README').check!
#
class ThreatScanner
  class Error < StandardError; end

  class MissingFileError      < Error; end
  class MissingScannerError   < Error; end
  class ScannerOperationError < Error; end
  class ThreatDetectedError   < Error; end

  def self.installed?
    system('which clamdscan > /dev/null 2>&1')
  end

  attr_reader :path

  def initialize(path)
    @path = path.respond_to?(:path) ? path.path : path
  end

  # Returns true if the given file is deemed safe, and false if it could not
  # be checked. Raises if a threat is detected, or the file did not exist.
  def check
    check!
  rescue MissingScannerError, ScannerOperationError
    false
  end

  # Returns true if the given file is deemed safe, and raises an exception
  # otherwise (if the file is unsafe / does not exist / scanner broke etc).
  def check!
    check_existence! && check_installed! && run_scanner!
  end

  private

  def check_existence!
    File.exist?(@path) || raise(MissingFileError, "#{@path} does not exist!")
  end

  def check_installed!
    self.class.installed? || raise(MissingScannerError, 'no scanner is available')
  end

  def run_scanner!
    `clamdscan --fdpass --quiet #{Shellwords.escape(@path)}`

    case $CHILD_STATUS.exitstatus
    when 0 then true
    when 1 then raise(ThreatDetectedError, "possible virus detected at #{@path}!")
    else        raise(ScannerOperationError, 'the scan was unable to complete')
    end
  end
end
