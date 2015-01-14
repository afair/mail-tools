require_relative "../test/test_helpers"

class TestMaildrop < MiniTest::Test

  def test_drop
    dr = Mail::Tools::Maildrop.new(MAILDROP_DIR)
    dr.clear!
    fn = dr.deliver(basic_message)
    assert File.exist?(fn)
    f = File.readlines(fn)
    assert_equal "me@example.com", f[0].chomp
    assert_match(/you@example.com/, f[1].chomp)
    assert_match(/\ASubject/, f[3])
  end

  def test_receive
    m = basic_message
    d = maildrop
    d.deliver(m)
    m2 = nil
    d.receive { |msg| m2 = msg }
    assert_equal m.message, m2.message
  end
end
