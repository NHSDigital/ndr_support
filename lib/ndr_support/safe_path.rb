require 'active_support/core_ext/object/blank'
require 'yaml'
require 'erb'

# Ruby has a built-in SecurityError class
#class SecurityError < StandardError
#end

# = SafePath
#
# SafePath is a class which contains path to a file or directory. It also holds "path space" and
# permissions. The path space is a directory. Everything in this directory and all the
# subdirectories can be accessed with the permissions given to the constructor. The instance of
# the class checks whether the path constructed points to a directory, whcih is in the
# "path space". The idea is to limit the access of the program to given directory.
#
# Example of usage is :
#   sp = SafePath("dbs_inbox")
#
# The root directory of the pathspace is in the file config/filesystem_paths.yml . In this case dbs_inbox has root
# /mounts/ron/dbs_inbox . Every path which starts with /mount/ron/dbs_inbox is considered as safe. If a path is constructed
# which is /mounts/ron/dbs_inbox/../../../etc/passwd for example then the class will evaluate the path and it will
# raise exception SecurityError.
#
# The paths can be constructed by using +, join or join!.
# Example:
#   This:
#     sp = SafePath("dbs_inbox")
#     sp + "/my_dir"
#   Points to:
#     /mounts/ron/dbs_inbox/my_dir
#
#
# The functions join and join! work in similar way. The difference between
# join and join! is that join creates new instance of the class SafePath and
# return it and join! doesn't create new instance, but works in-place and after
# that it returns reference to the current instance.
# The both operators can be used like that:
#   sp.join("/my_dir")  #this is the same as sp + "my_dir"
#   sp.join!("/my_dir") #this is NOT the same as sp "my_dir"
#
# Warning the function sp.path = "some_path" will treat some_path as absolute path
# and if it doesn't point to the root it will raise exception. The danger is that
# it returns the argument on the right hand side. So if it is a string the operator
# will return a string. This is the way ruby works. If it is used properly it shouldn't
# be a problem. The best way to use it is:
#   sp.path = sp.root + "my_dir"
# sp.root returns SafePath and after that + is called which also returns SafePath. So the
# right hand side of the expression is SafePath and the = will return SafePath.
#
class SafePath

  # Returns the list of safe 'root' filesystem locations, or raises
  # a SecurityError if no configuration has been provided.
  def self.fs_paths
    if defined?(@@fs_paths)
      @@fs_paths
    else
      fail SecurityError, 'SafePath not configured!'
    end
  end

  # Takes the path the filesystem_paths.yml file that
  # should be used. Attempting to reconfigure with
  # new settings will raise a security error.
  def self.configure!(filepath)
    if defined?(@@fs_paths)
      fail SecurityError, 'Attempt to re-assign SafePath config!'
    else
      File.open(filepath, 'r') do |file|
        @@fs_paths = YAML.load(ERB.new(file.read).result)
        @@fs_paths.freeze
      end
    end
  end

  # Takes:
  #   * path - This is a path to a directory. Usually a string.
  #   * path_space - This is identifier of the path space in whichi the system should work.
  #     it is a string. To find list of path spaces with their roots, please
  #     see config/filesystem_paths.yml
  #
  #  Raises:
  #    * ArgumentError
  #    * SecurityError
  #
  def initialize(path_space, root_suffix = '')
    # The class has to use different path definitions during test

    fs_paths = self.class.fs_paths

    platform = fs_paths.keys.select do |key|
      RUBY_PLATFORM.match key
    end[0]

    root_path_regexp = if platform == /mswin32|mingw32/
                        /\A([A-Z]:[\\\/]|\/\/)/
                       else
                        /\A\//
                       end

    fail ArgumentError, "The space #{path_space} doesn't exist. Please choose one of: #{fs_paths[platform].keys.inspect}" unless fs_paths[platform][path_space]
    fail ArgumentError, "The space #{path_space} is broken. The root path should be absolute path but it was #{fs_paths[platform][path_space]['root']}" unless fs_paths[platform][path_space]['root'].match(root_path_regexp)
    fail ArgumentError, "The space #{path_space} is broken. No permissions specified}" unless fs_paths[platform][path_space]['prms']

    # The function verify uses @root. Therefore first assign the root path
    # specified in the yaml file. After that verify that the root path
    # specified from the contructor is subpath of the path specified in the
    # yaml file. If it is not raise exception before anything else is done.
    #
    # The reason to assign @root 2 times is that it is better to have the
    # logic verifing the path in only one function. This way it is going
    # to be easier to maintain it and keep it secure.
    #

    @root = File.expand_path fs_paths[platform][path_space]['root']
    @root = verify(File.join(fs_paths[platform][path_space]['root'], root_suffix)) unless root_suffix.blank?

    @path_space = path_space
    @maximum_prms = fs_paths[platform][path_space]['prms']
    @prm = nil

    self.path = @root
  end

  def ==(other)
    other.class == SafePath and other.root.to_s == @root and other.permissions == self.permissions and other.to_s == self.to_s
  end

  # WARNING: do not use sp.to_s + from_attacker . This is unsafe!
  #
  # Returns:
  #   String
  #
  def to_s
    @path
  end

  # WARNING: do not use s.to_s + "my_path" . This is unsafe!
  #
  #  Returns:
  #    String
  #
  def to_str
    self.to_s
  end

  # Getter for permissions.
  #
  # Returns:
  #   Array
  def permissions
    if @prm
      @prm
    else
      @maximum_prms
    end
  end

  # Getter for path space identifier.
  #
  # Returns:
  #   Array
  #
  def path_space
    @path_space
  end

  # Getter for the root of the path space.
  #
  # Returns:
  #   SafePath
  #
  def root
    r = self.clone
    r.path = @root
    r.permissions = self.permissions
    r
  end

  # The permissions are specified in the yml file, but this function
  # can select subset of these permissions. It cannot select permission,
  # which is not specified in the yml file.
  #
  # Takes:
  #   * Array of permission or single permission - If it is array then
  #     tha array could contain duplicates and it also can be nested.
  #     All the duplicates will be removed and the array will be flattened
  #
  # Returns:
  #   Array - this is the reuslt of the assignment. Note it is the right hand side of the expression
  #
  # Raises:
  #   * ArgumentError
  #
  def permissions=(permissions)
    err_mess = "permissions has to be one or more of the values: #{@maximum_prms.inspect}\n but it was #{permissions.inspect}"

    @prm = [permissions].flatten.each do |prm|
      fail ArgumentError, err_mess unless @maximum_prms.include?(prm)
    end.uniq
  end

  # Setter for path.
  #
  # Takes:
  #   * path - The path.
  #
  # Returns:
  #   Array - this is the result of the assignment. Note it is the right hand side of the expression
  #
  # Raises:
  #   * SecurityError
  #
  # Warning avoid using this in expressions like this (safe_path_new = (safe_path.path = safe_path.root.to_s + "/test")) + path_from_attacker
  # This is unsafe!
  #
  def path=(path)
    @path = verify(path)
    self
  end

  # Another name for join
  def +(path)
    self.join(path)
  end

  # Used to construct path. It joins the current path with the given one.
  # Takes:
  #   * path - path to be concatenated
  #
  # Returns:
  #   New instance of SafePath which contains the new path.
  #
  # Raises:
  #   * SecurityError
  #
  def join(path)
    r = self.clone
    r.path = File.join(@path, path)
    r
  end

  # Used to construct path. It joins the current path with the given one.
  # Takes:
  #   * path - path to be concatenated
  #
  # Returns:
  #   Reference to the current instance. It works in-place
  #
  # Raises:
  #   * SecurityError
  #
  def join!(path)
    self.path = File.join(@path, path)
    self
  end

  def length()
    @path.length
  end

  private

  # Verifies whether the path is safe.
  def verify(path)
    epath = File.expand_path(path)
    fail SecurityError, "The given path is insecure. The path should point at #{@root}, but it points at #{epath}" unless epath.match(/\A#{Regexp.quote(@root)}/)
    epath
  end
end
