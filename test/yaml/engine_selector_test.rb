require 'test_helper'

class EngineSelectorTest < Minitest::Test
  include NdrSupport::YAML::EngineSelector

  test 'we should emit using psych' do
    assert_equal PSYCH, yaml_emitter
  end

  test 'should always use psych for loading yaml' do
    if syck_available?
      assert_equal PSYCH, yaml_loader_for("---\n:a: 1\n")
      assert_equal PSYCH, yaml_loader_for("--- hello\n...\n")
    else # Ruby 2.0+
      assert_equal PSYCH, yaml_loader_for("--- \n:a: 1\n")
      assert_equal PSYCH, yaml_loader_for("---\n:a: 1\n")

      assert_equal PSYCH, yaml_loader_for("--- hello\n")
      assert_equal PSYCH, yaml_loader_for("--- hello\n...\n")
    end
  end
end
