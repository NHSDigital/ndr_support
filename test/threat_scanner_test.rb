require 'test_helper'

# This tests our ThreatScanner extension
class ThreatScannerTest < Minitest::Test
  def setup
    @tempfile = Tempfile.new
    @scanner  = ThreatScanner.new(@tempfile)

    ThreatScanner.stubs(installed?: true)
    ThreatScanner.any_instance.stubs(:`)
  end

  def teardown
    @tempfile.close!
  end

  test 'can be initialised with a file' do
    assert_equal @tempfile.path, @scanner.path
  end

  test 'can be initialised with a path' do
    scanner = ThreatScanner.new(@tempfile.path)
    assert_equal @tempfile.path, scanner.path
  end

  test 'returns true if no threat is detected (when being strict)' do
    Process::Status.any_instance.stubs(exitstatus: 0)
    assert_equal true, @scanner.check!
  end

  test 'raises if a threat is detected (when being strict)' do
    Process::Status.any_instance.stubs(exitstatus: 1)
    assert_raises(ThreatScanner::ThreatDetectedError) { @scanner.check! }
  end

  test 'raises if the file does not exist (when being strict)' do
    @tempfile.close!
    assert_raises(ThreatScanner::MissingFileError) { @scanner.check! }
  end

  test 'raises if ClamAV is not installed (when being strict)' do
    ThreatScanner.stubs(installed?: false)
    assert_raises(ThreatScanner::MissingScannerError) { @scanner.check! }
  end

  test 'raises if there is an operational error (when being strict)' do
    Process::Status.any_instance.stubs(exitstatus: 2)
    assert_raises(ThreatScanner::ScannerOperationError) { @scanner.check! }
  end

  test 'returns true if no threat is detected (when being relaxed)' do
    Process::Status.any_instance.stubs(exitstatus: 0)
    assert_equal true, @scanner.check
  end

  test 'raises if a threat is detected (when being relaxed)' do
    Process::Status.any_instance.stubs(exitstatus: 1)
    assert_raises(ThreatScanner::ThreatDetectedError) { @scanner.check }
  end

  test 'raises if the file does not exist (when being relaxed)' do
    @tempfile.close!
    assert_raises(ThreatScanner::MissingFileError) { @scanner.check }
  end

  test 'returns false if ClamAV is not installed (when being relaxed)' do
    ThreatScanner.stubs(installed?: false)
    assert_equal false, @scanner.check
  end

  test 'returns false if there is an operational error (when being relaxed)' do
    Process::Status.any_instance.stubs(exitstatus: 2)
    assert_equal false, @scanner.check
  end
end
