require_relative "../test/test_helpers"

class TestMaildrop #< MiniTest::Test

  def test_drop
    dr = Mail::Tools::Maildrop.new(MAILDROP_DIR)
    dr.clear!
    fn = dr.deliver(basic_message)
    assert File.exist?(fn)
    f = File.readlines(fn)
    assert_equal "me@example.com", f[0].chomp
    assert_equal "you@example.com", f[1].chomp
    assert_match(/\ASubject/, f[3])
  end

  def test_receive
    m = basic_message
    d = maildrop
    r= d.deliver(m)
    m2 = nil
    d.receive { |msgin| m2 = msgin; true }
    assert_equal m.to_s, m2.to_s
    assert !File.exist?(r.info.join(File::SEPARATOR))
  end
end
