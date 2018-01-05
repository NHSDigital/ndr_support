require 'ndr_support/safe_path'

class SafeFile
  def initialize(*args)
    a = self.class.get_fname_mode_prms(*args)
    fname = a[0]
    mode = a[1]
    prms = a[2]

    if prms
      @file = File.new(fname, mode, prms)
    else
      @file = File.new(fname, mode)
    end

    # Just in case better clone the object
    # Ruby object are passed by reference
    @file_name = fname.clone
  end

  def self.open(*args)
    return SafeFile.new(*args) unless block_given?

    f = SafeFile.new(*args)
    yield f
    f.close
  end

  def close
    @file.close
  end

  def read
    verify @file_name, 'r'
    @file.read
  end

  def write(data)
    verify @file_name, 'w'
    @file.write(data)
  end

  def each(*args, &block)
    verify @file_name, 'r'
    @file.each(*args, &block)
  end
  alias_method :each_line, :each

  def path
    @file_name.clone
  end

  def self.extname(file_name)
    verify file_name
    File.extname(file_name)
  end

  def self.read(file_name)
    verify file_name, 'r'
    File.read(file_name)
  end

  def self.readlines(*args)
    fail ArgumentError, "Incorrect number of arguments - #{args.length}" if args.length > 2 or args.length == 0
    verify args[0], 'r'
    File.readlines(*args)
  end

  def self.directory?(file_name)
    verify file_name
    File.directory?(file_name)
  end

  def self.exist?(file_name)
    self.exists?(file_name)
  end

  def self.exists?(file_name)
    verify file_name
    File.exist?(file_name)
  end

  def self.file?(file_name)
    verify file_name
    File.file?(file_name)
  end

  def self.zero?(file_name)
    verify file_name
    File.zero?(file_name)
  end

  def self.basename(file_name, suffix = :none)
    verify file_name
    if suffix == :none
      File.basename(file_name)
    else
      File.basename(file_name, suffix)
    end
  end

  def self.safepath_to_string(fname)
    verify fname
    fname.to_s
  end

  def self.basename_file
    # SECURE: 02-08-2012 TPG Can't assign to __FILE__
    File.basename(__FILE__)
  end

  def self.dirname(path)
    verify path
    res = path.clone
    res.path = File.dirname(path)
    res
  end

  def self.delete(*list)
    verify list, 'w'

    list.each do |file|
      File.delete(file) if File.exist?(file)
    end.length
  end

  private

  def verify(file_names, prm = nil)
    self.class.verify(file_names, prm)
  end

  def self.verify(file_names, prm = nil)
    [file_names].flatten.each do |file_name|
      fail ArgumentError, "file_name should be of type SafePath, but it is #{file_name.class}" unless file_name.class == SafePath

      if prm
        [prm].flatten.each do |p|
          fail SecurityError, "Permissions denied. Cannot access the file #{file_name} with permissions #{prm}. The permissions are #{file_name.permissions}" unless file_name.permissions.include?(p)
        end
      end
    end
  end

  def self.verify_mode(file_name, mode)
    if mode.match(/\A(r\+)|(w\+)|(a\+)\Z/)
      verify file_name, ['w', 'r']
    elsif mode.match(/\Aw|a\Z/)
      verify file_name, ['w']
    elsif mode.match(/\Ar\Z/)
      verify file_name, ['r']
    else
      fail ArgumentError, "Incorrect mode. It should be one of: 'r', 'w', 'r+', 'w+', 'a', 'a+'"
    end
  end

  def self.get_fname_mode_prms(*args)
    case args.length
    when 1
      verify_mode(args[0], 'r')
      fname = args[0]
      mode = 'r'
      prms = nil

    when 2
      fail ArgumentError unless args[1].is_a?(Integer) || args[1].is_a?(String)

      if args[1].is_a?(Integer)
        verify_mode(args[0], 'r')
        mode = 'r'
        prms = args[1]
      else
        verify_mode(args[0], args[1])
        mode = args[1]
        prms = nil
      end

      fname = args[0]

    when 3
      fail ArgumentError unless args[1].is_a?(String) && args[2].is_a?(Integer)
      verify_mode(args[0], args[1])

      fname = args[0]
      mode = args[1]
      prms = args[2]
    else
      fail ArgumentError, "Incorrect number of arguments #{args.length}"
    end

    [fname, mode, prms]
  end
end
