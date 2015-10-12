require 'test_helper'

# Switch on the patientlimiter as though in external environment

class SafeFileTest < Minitest::Test
  def setup
    @not_empty_fpath = SafePath.new('test_space_rw').join('test_file_rw_not_empty')

    File.open(@not_empty_fpath, 'w') do |f|
      f.write 'I am not empty'
    end

    @empty_fpath = SafePath.new('test_space_rw').join('test_file_rw')

    File.open(@empty_fpath, 'w') do |f|
      f.write ''
    end
  end

  def teardown
    FileUtils.rm(Dir[SafePath.new('test_space_rw').join('*')])
  end

  ################################################################################
  # .new

  test 'constructor should accept safe_path only' do
    assert_raises(ArgumentError) { SafeFile.new }
    assert_raises(ArgumentError) { SafeFile.new('example_file', 'rw') }
  end

  test 'constructor should only allow string or numeric second argument' do
    assert_raises(ArgumentError) { SafeFile.new(@not_empty_fpath, {}) }
  end

  test 'should raise exception if try to write in read-only space' do
    assert_raises SecurityError do
      SafeFile.new(SafePath.new('test_space_r').join!('test_file_r'), 'a+')
    end

    assert_raises SecurityError do
      SafeFile.new(SafePath.new('test_space_r').join!('test_file_r'), 'a')
    end

    assert_raises SecurityError do
      SafeFile.new(SafePath.new('test_space_r').join!('test_file_r'), 'r+')
    end

    assert_raises SecurityError do
      SafeFile.new(SafePath.new('test_space_r').join!('test_file_r'), 'w')
    end
  end

  test 'should raise exception if try to read in write only space' do
    assert_raises SecurityError do
      SafeFile.new(SafePath.new('test_space_w').join!('test_file_w'), 'a+')
    end

    assert_raises SecurityError do
      SafeFile.new(SafePath.new('test_space_w').join!('test_file_w'), 'r+')
    end

    assert_raises SecurityError do
      SafeFile.new(SafePath.new('test_space_w').join!('test_file_w'), 'r')
    end
  end

  test 'should read from read-only space and write to write only space' do
    write_only_path = SafePath.new('test_space_w').join!('new_file_rw_new_file')
    read_only_path = SafePath.new('test_space_r').join!('new_file_rw_new_file')
    refute File.exist?(read_only_path)

    f = SafeFile.new(write_only_path, 'w')
    assert_equal 4, f.write('test')
    f.close

    assert File.exist?(read_only_path)

    f = SafeFile.new(read_only_path, 'r')
    assert_equal 'test', f.read
    f.close
  end

  test 'should read/write from file with new to rw space' do
    fpath = SafePath.new('test_space_rw').join!('new_file_rw_new_file')

    refute File.exist?(fpath)

    f = SafeFile.new(fpath, 'w')
    assert_equal 4, f.write('test')
    f.close

    assert File.exist?(fpath)

    f = SafeFile.new(fpath, 'r')
    assert_equal 'test', f.read
    f.close
  end

  test 'should accept mode types' do
    s = SafeFile.new(@empty_fpath, 'r')
    s.close

    s = SafeFile.new(@empty_fpath, 'w')
    s.close

    s = SafeFile.new(@empty_fpath, 'r+')
    s.close

    s = SafeFile.new(@empty_fpath, 'w+')
    s.close

    s = SafeFile.new(@empty_fpath, 'a+')
    s.close

    s = SafeFile.new(@empty_fpath, 'a')
    s.close
  end

  test 'should raise exception if incorect mode passed' do
    assert_raises ArgumentError do
      SafeFile.new(@empty_fpath, 'potato_mode')
    end

    assert_raises ArgumentError do
      SafeFile.new(@empty_fpath, 'rw+a+')
    end

    assert_raises ArgumentError do
      SafeFile.new(@empty_fpath, 'r+w+')
    end
  end

  test 'should accept permissions' do
    f = SafeFile.new(@empty_fpath, 'r', 755)
    f.close

    SafeFile.new(@empty_fpath, 755)
  end

  ################################################################################
  # ::open

  test '::open should accept safe_path only' do
    p = SafePath.new('test_space_rw').join('test1')

    refute File.exist?(p)

    assert_raises ArgumentError do
      SafeFile.open(p.to_s, 'r') do |f|
        f.write 'hohohoho'
      end
    end

    assert_raises ArgumentError do
      f = SafeFile.open(p.to_s, 'r')
      f.write 'hohohoho'
      f.close
    end

    refute File.exist?(p)
  end

  test '::open should check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join!('new_file_rw_blablabla')
    write_only_path = SafePath.new('test_space_w').join!('test_file_rw_not_empty')

    refute File.exist?(read_only_path)

    assert_raises SecurityError do
      SafeFile.open(read_only_path, 'w') do |f|
        f.write('test')
      end
    end

    refute File.exist?(read_only_path)

    fcontent = 'something else'

    assert_raises SecurityError do
      SafeFile.open(write_only_path, 'r') do |f|
        fcontent = f.read
      end
    end

    refute_equal fcontent, File.read(write_only_path)
  end

  test '::open should read/write from file' do
    fpath = SafePath.new('test_space_rw').join!('new_file_rw_blablabla')
    read_only_path = SafePath.new('test_space_r').join!('new_file_rw_blablabla')
    write_only_path = SafePath.new('test_space_w').join!('new_file_rw_blablabla')
    refute File.exist?(fpath)

    SafeFile.open(fpath, 'w') do |f|
      assert_equal 4, f.write('test')
    end

    SafeFile.open(fpath, 'r') do |f|
      assert_equal 'test', f.read
    end

    # Test how the defailt arguments work
    SafeFile.open(read_only_path) do |f|
      assert_equal 'test', f.read
    end

    # Test how the defailt arguments work
    assert_raises SecurityError do
      SafeFile.open(write_only_path) do |f|
        assert_equal 'test', f.read
      end
    end

    assert_equal 1, File.delete(fpath)
  end

  test '::open should accept fs permissions with block' do
    p = SafePath.new('test_space_rw').join('test1')

    SafeFile.open(p, 'w', 255) do |f|
      f.write 'test332'
    end

    assert File.exist?(p)
  end

  test '::open should accept fs permissions with no block' do
    p = SafePath.new('test_space_rw').join('test1')

    f = SafeFile.open(p, 'w', 255)
    f.close

    assert File.exist?(p)
  end

  test '::open should work as new if no block passed' do
    p = SafePath.new('test_space_r').join('test_file_rw')

    f = SafeFile.open(p)
    assert_equal SafeFile, f.class
    f.close
  end

  ################################################################################
  # ::read

  test '::read should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.read @not_empty_fpath.to_s
    end
  end

  test '::read should check pathspace permissions' do
    write_only_path = SafePath.new('test_space_w').join('test_file_rw')

    fcontent = 'none'
    assert_raises SecurityError do
      fcontent = SafeFile.read(write_only_path)
    end
    assert_equal 'none', fcontent
  end

  test '::read should read file content' do
    assert File.read(@not_empty_fpath), SafeFile.read(@not_empty_fpath)
  end

  ################################################################################
  # .read

  test '#read should check pathspace permissions' do
    p = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    f = SafeFile.new(p, 'w')
    assert_raises SecurityError do
      f.read
    end
    f.close
  end

  test '#read should read read-only namespace' do
    p = SafePath.new('test_space_r').join('test_file_rw_not_empty')

    f = SafeFile.new(p, 'r')
    assert_equal 'I am not empty', f.read
    f.close
  end

  ################################################################################
  # .write

  test '#write should check pathspace permissions' do
    p = SafePath.new('test_space_r').join('test_file_rw_not_empty')

    f = SafeFile.new(p, 'r')
    assert_raises SecurityError do
      f.write 'junk'
    end
    f.close
  end

  test '#write should write to write namespace' do
    p = SafePath.new('test_space_rw').join('test1')

    f = SafeFile.new(p, 'w')
    f.write 'good test'
    f.close

    f = SafeFile.new(p, 'r')
    assert_equal 'good test', f.read
    f.close

    assert File.exist? p.to_s
    File.delete p
  end

  ################################################################################
  # .path

  test '#path should return instance of SafePath' do
    p = SafePath.new('test_space_r').join('test_file_rw_not_empty')

    f = SafeFile.new(p)
    assert_equal SafePath, f.path.class
    refute_equal p.object_id, f.path.object_id
    assert_equal p, f.path
  end

  ################################################################################
  # .close

  test '#close should close the file' do
    p = SafePath.new('test_space_w').join('test_file_rw')
    f = SafeFile.new(p, 'w')
    f.write 'test'
    f.close
  end

  ################################################################################
  # ::extname

  test '::extname should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.extname 'bad/extention.rb'
    end
  end

  test '::extname should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    SafeFile.extname read_only_path
    SafeFile.extname write_only_path
  end

  test '::extname should return the extention only' do
    assert_equal '.rb', SafeFile.extname(SafePath.new('test_space_r').join('test_file.rb'))
    assert_equal '', SafeFile.extname(SafePath.new('test_space_r').join('test_file'))
  end

  ################################################################################
  # ::basename

  test '::basename should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.basename('some/evil/path.rb')
    end

    assert_raises ArgumentError do
      SafeFile.basename('some/evil/path.rb', '.rb')
    end
  end

  test '::basename should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    SafeFile.basename read_only_path
    SafeFile.basename write_only_path
  end

  test '::basename should should return the basename' do
    p = SafePath.new('test_space_rw').join('myfile.rb')

    assert_equal 'myfile.rb', SafeFile.basename(p)
    assert_equal 'myfile', SafeFile.basename(p, '.rb')
  end

  ################################################################################
  # ::readlines

  test "::readlines shouldn't accept more than 2 and less than 1 arguments" do
    p = SafePath.new('test_space_r').join('test_file_rw')
    assert_raises ArgumentError do
      SafeFile.readlines
    end

    assert_raises ArgumentError do
      SafeFile.readlines(p, 'junk_argument1', :junk_argument2)
    end

    assert_raises ArgumentError do
      SafeFile.readlines('junk/path/to/file.rb')
    end
  end

  test '::readlines should check pathspace permissions' do
    p = SafePath.new('test_space_w').join('test_file_rw')
    assert_raises SecurityError do
      SafeFile.readlines(p)
    end
  end

  test '::readlines should read lines from file' do
    p = SafePath.new('test_space_r').join('test_file_rw')
    # Use file because this test should be independent on the rest of the functionality of SafeFile
    File.open(p, 'w') do |f|
      f.write "there are three\nlines in this file\nand eight words"
    end

    lines = SafeFile.readlines(p)

    assert_equal 3, lines.length
    assert_equal "there are three\n", lines[0]
    assert_equal "lines in this file\n", lines[1]
    assert_equal 'and eight words', lines[2]

    lines = SafeFile.readlines(p, ' ')
    assert_equal 8, lines.length
    assert_equal 'there ', lines[0]
  end

  ################################################################################
  # ::directory?

  test '::directory? should accept only safe_path' do
    assert_raises ArgumentError do
      SafeFile.directory?('some/junk/path')
    end
  end

  test '::directory? should NOT check for pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    SafeFile.directory?(read_only_path)
    SafeFile.directory?(write_only_path)
  end

  test '::directory? should return true if the path is a directory and false otherwise' do
    p = SafePath.new('test_space_r')
    assert SafeFile.directory?(p)
    refute SafeFile.directory?(p.join('test_file_rw_not_empty'))
  end

  ################################################################################
  # ::exist? ::exists?

  test '::exist? and ::exists? should accept only safe_path' do
    assert_raises ArgumentError do
      SafeFile.exist?('some/junk/path')
    end

    assert_raises ArgumentError do
      SafeFile.exist?('some/junk/path')
    end
  end

  test '::exist? and ::exists? should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    SafeFile.exist?(read_only_path)
    SafeFile.exist?(write_only_path)
    SafeFile.exist?(read_only_path)
    SafeFile.exist?(write_only_path)
  end

  test 'exist? and exists? should return true if the file exists and false otherwise' do
    real = SafePath.new('test_space_r').join('test_file_rw')
    junk = SafePath.new('test_space_r').join('test_file_rw_junk')

    assert SafeFile.exist?(real)
    assert SafeFile.exist?(real)

    refute SafeFile.exist?(junk)
    refute SafeFile.exist?(junk)
  end

  ################################################################################
  # ::file?

  test '::file? should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.file?('some/junk.path')
    end
  end

  test '::file? should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    SafeFile.file?(read_only_path)
    SafeFile.file?(write_only_path)
  end

  test 'file? should return true of the path is file and false otherwise' do
    file = SafePath.new('test_space_r').join('test_file_rw')
    dir = SafePath.new('test_space_r')

    assert SafeFile.file?(file)
    refute SafeFile.file?(dir)
  end

  ################################################################################
  # ::zero?

  test '::zero? should accept only SafePath' do
    assert_raises ArgumentError do
      SafeFile.zero? SafePath.new('test_space_w').join!('test_file_rw').to_s
    end
  end

  test '::zero? should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    SafeFile.zero?(read_only_path)
    SafeFile.zero?(write_only_path)
  end

  test '::zero? should return true when the file is empty and false otherwise' do
    assert SafeFile.zero? SafePath.new('test_space_rw').join!('test_file_rw')
    refute SafeFile.zero?(SafePath.new('test_space_rw').join!('test_file_rw_not_empty'))
  end

  ################################################################################
  # ::dirname

  test '::dirname should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.dirname('some/junk/path')
    end
  end

  test '::dirname should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    SafeFile.dirname(read_only_path)
    SafeFile.dirname(write_only_path)
  end

  test '::dirname should return the directory' do
    p = SafePath.new('test_space_r')

    assert_equal SafePath, SafeFile.dirname(p.join('test_file_rw')).class
    refute_equal p.object_id, SafeFile.dirname(p.join('test_file_rw')).object_id

    assert_equal p.to_s, SafeFile.dirname(p.join('test_file_rw')).to_s
  end

  ################################################################################
  # ::delete

  test '::delete should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.delete('test_path')
    end
  end

  test '::delete should check pathspace permissions' do
    assert_raises SecurityError do
      SafeFile.delete(SafePath.new('test_space_r').join!('test_file_r'))
    end
  end

  test '::delete should delete file/files' do
    sp = SafePath.new('test_space_w').join!('new_test_file')

    group = [SafePath.new('test_space_w').join!('new_test_file1'),
             SafePath.new('test_space_w').join!('new_test_file2'),
             SafePath.new('test_space_w').join!('new_test_file3')]

    (group + [sp]).each do |fname|
      # This test should't depend on the rest of the functionality of SafeFile
      File.open(fname, 'w') { |f| f.write 'test' }
    end

    SafeFile.delete sp

    refute File.exist?(sp)

    SafeFile.delete(*group)

    group.each do |fname|
      refute File.exist?(fname)
    end
  end
end
