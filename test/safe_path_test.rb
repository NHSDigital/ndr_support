require 'test_helper'

# Switch on the patientlimiter as though in external environment

class SafePathTest < Minitest::Test
  def setup
     @sp = SafePath.new("dbs_outbox").join!("/usr/lib")
  end

  def test_reconfiguring_exception
    # We need SafePath to be well-configured for testing already:
    SafePath.fs_paths # force configuration
    assert_raises(SecurityError) { SafePath.configure! 'dodgy_config.yml' }
  end

  test 'path passed to the constructor is always relative to the root of the path space' do
    assert_equal @sp.to_s, "/mounts/ron/dbs_outbox/usr/lib"
  end

  test 'permissions are combination of w or r or x' do
    assert_equal Array, @sp.permissions.class
    assert_equal ["r", "w", "x"], @sp.permissions

    @sp.permissions = "r"
    assert_equal ["r"], @sp.permissions

    # The assignment of the permissions preserves the order, although this is not
    # necessary.
    @sp.permissions = ["w", "r"]
    assert_equal ["w", "r"], @sp.permissions

    # The class shouldn't keep duplicates and should flattent the arrays
    @sp.permissions = ["w", "r", "x", "w", "r", ["x", "r"]]
    assert_equal ["w", "r", "x"], @sp.permissions
  end

  test 'safe path raises exception if parmission different from rwx is passed' do
    @sp.permissions= "w"
    assert_raises ArgumentError do
      @sp.permissions = ["r", "w", "potato"]
    end

    # The class sould keep it's old permissions in case of raised exception
    assert_equal ["w"], @sp.permissions
  end

  test 'safe path should remember the pathspace' do
    assert_equal "dbs_outbox", @sp.path_space
  end

  test 'safe path should remember root and return another instance of safe path rather than string' do
    @sp.permissions = ["w", "x"]
    root = @sp.root
    assert_equal  SafePath, @sp.root.class
    assert_equal "/mounts/ron/dbs_outbox", root.to_s

    assert_equal @sp.permissions, root.permissions
    assert_equal @sp.path_space, root.path_space
  end

  test 'safe path should raise exception if unsafe path passed to constructor' do
    assert_raises SecurityError do
      unsafe = SafePath.new("dbs_outbox").join!("../../../evil_path")
    end
  end

  test 'safe path should raise expecption if incorrect path is assigned' do
    assert_raises SecurityError do
      @sp.path= "/etc/passwd"
    end

    assert_raises SecurityError do
      @sp.path= "/mounts/ron/dbs_outbox/../../../evil_path"
    end
  end

  test 'join should return SafePath' do
    assert_equal SafePath, @sp.join("/test").class
  end

  test 'join sould raise exception if insecure path constructed' do
    assert_raises SecurityError do
      @sp.join("../../../evil_path")
    end
  end

  test 'join should create new object' do
    refute_equal @sp.object_id, @sp.join("test").object_id
  end

  test 'join! should return SafePath' do
    assert_equal SafePath, @sp.join!("/test").class
  end

  test 'join! sould raise exception if insecure path constructed' do
    path = @sp.to_s

    assert_raises SecurityError do
      @sp.join!("/../../../evil_path")
    end

    # if join is unsuccessful then it shouldn't alter the path
    assert_equal path, @sp.to_s
  end

  test 'join! should work in-place' do
    assert_equal @sp.object_id, @sp.join!("test").object_id
  end

  test '+ should return SafePath' do
    assert_equal SafePath, (@sp + "/test").class
  end

  test '+ sould raise exception if insecure path constructed' do
    assert_raises SecurityError do
      @sp + "../../../evil_path"
    end
  end

  test '+ should create new object' do
    refute_equal @sp.object_id, (@sp + "test").object_id
  end

  test "constructor should raise exception if the path space doesn't exist" do
    assert_raises ArgumentError do
      sp = SafePath.new("potato_space")
    end
  end

  test 'constructor should raise exception if path space is broken' do
    assert_raises ArgumentError do
      sp = SafePath.new("broken_space")
    end
  end


  test 'should reject root paths that are not subpath of the root specified in the yaml file' do
    assert_raises SecurityError do
      sp = SafePath.new("dbs_outbox", "../../evil_path")
    end
  end

  test 'should accept root paths that are subpath of the root specified in the yaml file' do
    assert_equal "/mounts/ron/dbs_outbox/nice_path/path", SafePath.new("dbs_outbox", "nice_path/path").root.to_s
  end

  test 'should restrict the access only to the subpath specified in the contructor rather than the root in the yaml file' do
    assert_raises SecurityError do
      sp = SafePath.new("dbs_outbox", "nice_path/path").join!("../evil_path_under_the_root")
    end

    assert_raises SecurityError do
      sp = SafePath.new("dbs_outbox", "nice_path/path")
      sp.path = "/mounts/ron/dbs_outbox/evil_path"
    end

    assert_raises SecurityError do
      sp = SafePath.new("dbs_outbox", "nice_path/path").join("../../evil_path")
    end

    assert_raises SecurityError do
      sp = SafePath.new("dbs_outbox", "nice_path/path") + "../../evil_path"
    end
  end

end

# TODO:
# Alternative .
