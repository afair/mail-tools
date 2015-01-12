require_relative "../test/test_helpers"

class TestRecipients < MiniTest::Test
  def test_initialize_empty_message
    r = Mail::Tools::Recipients.new([])
    #p r
    assert_equal r.count, 0
  end
end
