require 'test_helper'

# Tests obfuscation library
class ObfuscatorTest < Minitest::Test
  test 'deterministic seed should give consistent obfuscation' do
    seed1 = 1383023878118423080153274094615300156
    assert_equal 'CE PSEQQH', NdrSupport::Obfuscator.obfuscate('JO BLOGGS', seed1)
    assert_equal 'CE PSEQQH', NdrSupport::Obfuscator.obfuscate('JO BLOGGS', seed1),
                 'consistent re-obfuscation'
    assert_equal 'CE PSEQQH', NdrSupport::Obfuscator.obfuscate('Jo Bloggs', seed1),
                 'case insensitive'
    assert_equal 'CEZG PTIQQH', NdrSupport::Obfuscator.obfuscate('JOHN BRIGGS', seed1)
  end

  test 'different seeds should obfuscate differently' do
    seed2 = 33333285080880515415022777373811069493
    assert_equal 'VI RQICCZ', NdrSupport::Obfuscator.obfuscate('JO BLOGGS', seed2)
  end

  test 'test seed setup' do
    seed3 = 24978785977027615655244702873942606627
    assert_equal '781 RACO RXHOOX', NdrSupport::Obfuscator.obfuscate('369 Some Street', seed3)
    NdrSupport::Obfuscator.setup(seed3)
    assert_equal '781 RACO RXHOOX', NdrSupport::Obfuscator.obfuscate('369 Some Street')
  end
end
