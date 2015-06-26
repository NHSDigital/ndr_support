require 'test_helper'

class EngineSelectorTest < ActiveSupport::TestCase
  include NdrSupport::YAML::EngineSelector

  # TODO: this is a temporary test, until everything
  #       is running on Ruby 1.9.3. and switched to emitting Psych
  test 'we should emit using syck where possible' do
    if !universal_psych_support?
      assert_equal SYCK, yaml_emitter
    else # Ruby 2.0+
      assert_equal PSYCH, yaml_emitter
    end
  end

  test 'should pick the correct loading engine' do
    if syck_available?
      assert_equal SYCK, yaml_loader_for("--- \n:a: 1\n")
      assert_equal PSYCH, yaml_loader_for("---\n:a: 1\n")

      assert_equal SYCK, yaml_loader_for("--- hello\n")
      assert_equal PSYCH, yaml_loader_for("--- hello\n...\n")
    else # Ruby 2.0+
      assert_equal PSYCH, yaml_loader_for("--- \n:a: 1\n")
      assert_equal PSYCH, yaml_loader_for("---\n:a: 1\n")

      assert_equal PSYCH, yaml_loader_for("--- hello\n")
      assert_equal PSYCH, yaml_loader_for("--- hello\n...\n")
    end
  end
end
