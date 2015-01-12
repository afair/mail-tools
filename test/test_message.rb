require_relative "../test/test_helpers"

class TestMessage < MiniTest::Test
  MSG_BODY="Subject: Testing\n\nHello Message"
  MSG_RP="returns@example.com"
  MSG_TO=%w(to@example.com to2@example.com)

  def test_initialize_empty_message
    m = Mail::Tools::Message.new
    assert_equal m.message, ''
    assert_equal m.return_path, '<>'
    assert_equal m.recipients.count, 0
  end

  def test_full_message
    m = Mail::Tools::Message.new(MSG_BODY, MSG_RP, MSG_TO)
    assert_equal m.message, MSG_BODY
    assert_equal m.return_path, MSG_RP
    assert_equal m.recipients.count, 2
  end
end
