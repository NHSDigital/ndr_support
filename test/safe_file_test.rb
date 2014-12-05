require 'test_helper'

# Switch on the patientlimiter as though in external environment

class SafeFileTest < ActiveSupport::TestCase

  def setup
    @not_empty_fpath = SafePath.new("test_space_rw").join("test_file_rw_not_empty")

    File.open(@not_empty_fpath, "w") do |f|
      f.write "I am not empty"
    end

    @empty_fpath = SafePath.new("test_space_rw").join("test_file_rw")

    File.open(@empty_fpath, "w") do |f|
      f.write ""
    end
  end

  def teardown
    FileUtils.rm(Dir[SafePath.new("test_space_rw").join('*')])
  end

################################################################################
# .new

  test 'constructor should accept safe_path only' do
    assert_raises ArgumentError do
      s = SafeFile.new("example_file", "rw")
    end
  end


  test 'should raise exception if try to write in read-only space' do
    assert_raises SecurityError do
      s = SafeFile.new(SafePath.new("test_space_r").join!("test_file_r"), "a+")
    end

    assert_raises SecurityError do
      s = SafeFile.new(SafePath.new("test_space_r").join!("test_file_r"), "a")
    end

    assert_raises SecurityError do
      s = SafeFile.new(SafePath.new("test_space_r").join!("test_file_r"), "r+")
    end

    assert_raises SecurityError do
      s = SafeFile.new(SafePath.new("test_space_r").join!("test_file_r"), "w")
    end
  end


  test 'should raise exception if try to read in write only space' do
    assert_raises SecurityError do
      s = SafeFile.new(SafePath.new("test_space_w").join!("test_file_w"), "a+")
    end

    assert_raises SecurityError do
      s = SafeFile.new(SafePath.new("test_space_w").join!("test_file_w"), "r+")
    end

    assert_raises SecurityError do
      s = SafeFile.new(SafePath.new("test_space_w").join!("test_file_w"), "r")
    end
  end


  test 'should read from read-only space and write to write only space' do
    write_only_path = SafePath.new("test_space_w").join!("new_file_rw_new_file")
    read_only_path = SafePath.new("test_space_r").join!("new_file_rw_new_file")
    assert !File.exists?(read_only_path)


    assert_nothing_raised do
      f = SafeFile.new(write_only_path, "w")
      assert_equal 4, f.write("test")
      f.close
    end

    assert File.exists?(read_only_path)

    assert_nothing_raised do
      f = SafeFile.new(read_only_path, "r")
      assert_equal "test", f.read
      f.close
    end
  end

  test 'should read/write from file with new to rw space' do
    fpath = SafePath.new("test_space_rw").join!("new_file_rw_new_file")

    assert !File.exists?(fpath)


    assert_nothing_raised do
      f = SafeFile.new(fpath, "w")
      assert_equal 4, f.write("test")
      f.close
    end

    assert File.exists?(fpath)

    assert_nothing_raised do
      f = SafeFile.new(fpath, "r")
      assert_equal "test", f.read
      f.close
    end

  end


  test 'should accept mode types' do
    assert_nothing_raised do
      s = SafeFile.new(@empty_fpath, "r")
      s.close
    end

    assert_nothing_raised do
      s = SafeFile.new(@empty_fpath, "w")
      s.close
    end

    assert_nothing_raised do
      s = SafeFile.new(@empty_fpath, "r+")
      s.close
    end

    assert_nothing_raised do
      s = SafeFile.new(@empty_fpath, "w+")
      s.close
    end

    assert_nothing_raised do
      s = SafeFile.new(@empty_fpath, "a+")
      s.close
    end

    assert_nothing_raised do
      s = SafeFile.new(@empty_fpath, "a")
      s.close
    end
  end


  test 'should raise exception if incorect mode passed' do
    assert_raises ArgumentError do
      s = SafeFile.new(@empty_fpath, "potato_mode")
    end

    assert_raises ArgumentError do
      s = SafeFile.new(@empty_fpath, "rw+a+")
    end

    assert_raises ArgumentError do
      s = SafeFile.new(@empty_fpath, "r+w+")
    end
  end


  test 'should accept permissions' do
    assert_nothing_raised do
      f = SafeFile.new(@empty_fpath, "r", 755)
      f.close
    end

    assert_nothing_raised do
      s = SafeFile.new(@empty_fpath, 755)
    end
  end


################################################################################
# ::open
  test '::open should accept safe_path only' do
    p = SafePath.new("test_space_rw").join("test1")

    assert !File.exists?(p)

    assert_raises ArgumentError do
      SafeFile.open(p.to_s, "r") do |f|
        f.write "hohohoho"
      end
    end

    assert_raises ArgumentError do
      f = SafeFile.open(p.to_s, "r")
      f.write "hohohoho"
      f.close
    end

    assert !File.exists?(p)
  end


  test '::open should check pathspace permissions' do
    read_only_path = SafePath.new("test_space_r").join!("new_file_rw_blablabla")
    write_only_path = SafePath.new("test_space_w").join!("test_file_rw_not_empty")

    assert !File.exists?(read_only_path)

    assert_raises SecurityError do
      SafeFile.open(read_only_path, "w") do |f|
        f.write("test")
      end
    end

    assert !File.exists?(read_only_path)

    fcontent = "something else"

    assert_raises SecurityError do
      SafeFile.open(write_only_path, "r") do |f|
        fcontent = f.read
      end
    end

    assert_not_equal fcontent, File.read(write_only_path)
  end


  test '::open should read/write from file' do
    fpath = SafePath.new("test_space_rw").join!("new_file_rw_blablabla")
    read_only_path = SafePath.new("test_space_r").join!("new_file_rw_blablabla")
    write_only_path = SafePath.new("test_space_w").join!("new_file_rw_blablabla")
    assert !File.exists?(fpath)


    assert_nothing_raised do
      SafeFile.open(fpath, "w") do |f|
        assert_equal 4, f.write("test")
      end
    end

    assert_nothing_raised do
      SafeFile.open(fpath, "r") do |f|
        assert_equal "test", f.read
      end
    end

    # Test how the defailt arguments work
    assert_nothing_raised do
      SafeFile.open(read_only_path) do |f|
        assert_equal "test", f.read
      end
    end

    # Test how the defailt arguments work
    assert_raises SecurityError do
      SafeFile.open(write_only_path) do |f|
        assert_equal "test", f.read
      end
    end

    assert_equal 1, File.delete(fpath)
  end


  test '::open should accept fs permissions with block' do
    p = SafePath.new('test_space_rw').join('test1')

    assert_nothing_raised do
      SafeFile.open(p, "w", 255) {|f|
        f.write "test332"
      }
    end

    assert File.exists?(p)

  end

  test '::open should accept fs permissions with no block' do
    p = SafePath.new('test_space_rw').join('test1')

    assert_nothing_raised do
      f = SafeFile.open(p, "w", 255)
      f.close
    end

    assert File.exists?(p)
  end

  test '::open should work as new if no block passed' do
    p = SafePath.new('test_space_r').join('test_file_rw')

    assert_nothing_raised do
      f = SafeFile.open(p)
      assert_equal SafeFile, f.class
      f.close
    end
  end

################################################################################
# ::read
  test '::read should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.read @not_empty_fpath.to_s
    end
  end

  test '::read should check pathspace permissions' do
    write_only_path = SafePath.new("test_space_w").join("test_file_rw")

    fcontent = "none"
    assert_raises SecurityError do
      fcontent = SafeFile.read(write_only_path)
    end
    assert_equal "none", fcontent

  end

  test '::read should read file content' do
    assert_nothing_raised do
      assert File.read(@not_empty_fpath), SafeFile.read(@not_empty_fpath)
    end
  end

################################################################################
# .read

  test "#read should check pathspace permissions" do
    p = SafePath.new("test_space_w").join('test_file_rw_not_empty')

    f = SafeFile.new(p, "w")
    assert_raises SecurityError do
      content = f.read
    end
    f.close

  end

  test "#read should read read-only namespace" do
    p = SafePath.new("test_space_r").join('test_file_rw_not_empty')

    f = SafeFile.new(p, "r")
    assert_nothing_raised do
      assert_equal "I am not empty", f.read
    end
    f.close

  end


################################################################################
# .write

  test "#write should check pathspace permissions" do
    p = SafePath.new("test_space_r").join('test_file_rw_not_empty')

    f = SafeFile.new(p, "r")
    assert_raises SecurityError do
      f.write "junk"
    end
    f.close
  end


  test "#write should write to write namespace" do
    p = SafePath.new("test_space_rw").join('test1')

    f = SafeFile.new(p, "w")
    assert_nothing_raised do
      f.write "good test"
    end
    f.close

    f = SafeFile.new(p, "r")
    assert_nothing_raised do
      assert_equal "good test", f.read
    end
    f.close

    assert File.exists? p.to_s
    File.delete p
  end


################################################################################
# .path

  test "#path should return instance of SafePath" do
    p = SafePath.new('test_space_r').join('test_file_rw_not_empty')

    f = SafeFile.new(p)
    assert_equal SafePath, f.path.class
    assert_not_equal p.object_id, f.path.object_id
    assert_equal p, f.path
  end

################################################################################
# .close

  test "#close should close the file" do
    p = SafePath.new('test_space_w').join('test_file_rw')
    f = SafeFile.new(p, "w")
    f.write "test"
    assert_nothing_raised do
      f.close
    end
  end


################################################################################
# ::extname
  test '::extname should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.extname "bad/extention.rb"
    end
  end


  test '::extname should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    assert_nothing_raised do
      SafeFile.extname read_only_path
    end

    assert_nothing_raised do
      SafeFile.extname write_only_path
    end
  end

  test '::extname should return the extention only' do
    assert_nothing_raised do
      assert_equal ".rb", SafeFile.extname(SafePath.new('test_space_r').join("test_file.rb"))
    end

    assert_nothing_raised do
      assert_equal "", SafeFile.extname(SafePath.new('test_space_r').join("test_file"))
    end
  end

################################################################################
# ::basename

  test '::basename should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.basename("some/evil/path.rb")
    end

    assert_raises ArgumentError do
      SafeFile.basename("some/evil/path.rb", ".rb")
    end
  end

  test '::basename should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    assert_nothing_raised do
      SafeFile.basename read_only_path
    end

    assert_nothing_raised do
      SafeFile.basename write_only_path
    end
  end

  test '::basename should should return the basename' do
    p = SafePath.new("test_space_rw").join("myfile.rb")

    assert_nothing_raised do
      assert_equal "myfile.rb", SafeFile.basename(p)
    end

    assert_nothing_raised do
      assert_equal "myfile", SafeFile.basename(p, ".rb")
    end
  end

################################################################################
# ::readlines

  test "::readlines shouldn't accept more than 2 and less than 1 arguments" do
    p = SafePath.new('test_space_r').join('test_file_rw')
    assert_raises ArgumentError do
      lines = SafeFile.readlines()
    end

    assert_raises ArgumentError do
      lines = SafeFile.readlines(p, "junk_argument1", :junk_argument2)
    end

    assert_raises ArgumentError do
      lines = SafeFile.readlines("junk/path/to/file.rb")
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
    File.open(p, "w") do |f|
      f.write "there are three\nlines in this file\nand eight words"
    end

    lines = SafeFile.readlines(p)

    assert_equal 3, lines.length
    assert_equal "there are three\n", lines[0]
    assert_equal "lines in this file\n", lines[1]
    assert_equal "and eight words", lines[2]

    lines = SafeFile.readlines(p, " ")
    assert_equal 8, lines.length
    assert_equal "there ", lines[0]
  end

################################################################################
# ::directory?

  test '::directory? should accept only safe_path' do

    assert_raises ArgumentError do
      SafeFile.directory?("some/junk/path")
    end
  end

  test '::directory? should NOT check for pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    assert_nothing_raised do
      SafeFile.directory?(read_only_path)
    end

    assert_nothing_raised do
      SafeFile.directory?(write_only_path)
    end
  end

  test '::directory? should return true if the path is a directory and false otherwise' do
    p = SafePath.new('test_space_r')
    assert_nothing_raised do
      assert SafeFile.directory?(p)
    end

    assert_nothing_raised do
      assert !SafeFile.directory?(p.join("test_file_rw_not_empty"))
    end

  end

################################################################################
# ::exist? ::exists?

  test '::exist? and ::exists? should accept only safe_path' do
    assert_raises ArgumentError do
      SafeFile.exist?("some/junk/path")
    end

    assert_raises ArgumentError do
      SafeFile.exists?("some/junk/path")
    end
  end

  test '::exist? and ::exists? should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    assert_nothing_raised do
      SafeFile.exist?(read_only_path)
    end

    assert_nothing_raised do
      SafeFile.exist?(write_only_path)
    end

    assert_nothing_raised do
      SafeFile.exists?(read_only_path)
    end

    assert_nothing_raised do
      SafeFile.exists?(write_only_path)
    end
  end

  test 'exist? and exists? should return true if the file exists and false otherwise' do
    real = SafePath.new('test_space_r').join('test_file_rw')
    junk = SafePath.new('test_space_r').join('test_file_rw_junk')

    assert SafeFile.exist?(real)
    assert SafeFile.exists?(real)

    assert !SafeFile.exist?(junk)
    assert !SafeFile.exists?(junk)
  end

################################################################################
# ::file?

  test '::file? should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.file?("some/junk.path")
    end
  end

  test '::file? should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    assert_nothing_raised do
      SafeFile.file?(read_only_path)
    end

    assert_nothing_raised do
      SafeFile.file?(write_only_path)
    end
  end

  test 'file? should return true of the path is file and false otherwise' do
    file = SafePath.new('test_space_r').join('test_file_rw')
    dir = SafePath.new('test_space_r')

    assert SafeFile.file?(file)
    assert !SafeFile.file?(dir)
  end

################################################################################
# ::zero?

  test '::zero? should accept only SafePath' do
    assert_raises ArgumentError do
      SafeFile.zero? SafePath.new("test_space_w").join!("test_file_rw").to_s
    end
  end

  test '::zero? should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    assert_nothing_raised do
      SafeFile.zero?(read_only_path)
    end

    assert_nothing_raised do
      SafeFile.zero?(write_only_path)
    end
  end

  test '::zero? should return true when the file is empty and false otherwise' do
    assert SafeFile.zero? SafePath.new("test_space_rw").join!("test_file_rw")
    assert !SafeFile.zero?(SafePath.new("test_space_rw").join!("test_file_rw_not_empty"))
  end

################################################################################
# ::dirname

  test '::dirname should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.dirname("some/junk/path")
    end
  end

  test '::dirname should NOT check pathspace permissions' do
    read_only_path = SafePath.new('test_space_r').join('test_file_rw_not_empty')
    write_only_path = SafePath.new('test_space_w').join('test_file_rw_not_empty')

    assert_nothing_raised do
      SafeFile.dirname(read_only_path)
    end

    assert_nothing_raised do
      SafeFile.dirname(write_only_path)
    end
  end

  test '::dirname should return the directory' do
    p = SafePath.new("test_space_r")

    assert_equal SafePath, SafeFile.dirname(p.join("test_file_rw")).class
    assert_not_equal p.object_id, SafeFile.dirname(p.join("test_file_rw")).object_id

    assert_nothing_raised do
      assert_equal p.to_s, SafeFile.dirname(p.join("test_file_rw")).to_s
    end
  end

################################################################################
# ::delete

  test '::delete should accept safe_path only' do
    assert_raises ArgumentError do
      SafeFile.delete("test_path")
    end
  end

  test '::delete should check pathspace permissions' do
    assert_raises SecurityError do
      SafeFile.delete(SafePath.new("test_space_r").join!("test_file_r"))
    end
  end

  test '::delete should delete file/files' do
    sp = SafePath.new("test_space_w").join!("new_test_file")

    group = [SafePath.new("test_space_w").join!("new_test_file1"),
             SafePath.new("test_space_w").join!("new_test_file2"),
             SafePath.new("test_space_w").join!("new_test_file3")]

    (group + [sp]).each do |fname|
      # This test should't depend on the rest of the functionality of SafeFile
      File.open(fname, "w") { |f| f.write "test" }
    end

    assert_nothing_raised do
      SafeFile.delete sp
    end

    assert !File.exists?(sp)

    assert_nothing_raised do
      SafeFile.delete *group
    end

    group.each do |fname|
      assert !File.exists?(fname)
    end

  end

end
