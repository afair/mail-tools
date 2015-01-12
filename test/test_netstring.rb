require_relative "../test/test_helpers"

class TestNetstring < MiniTest::Test

  def test_encode
    s = Mail::Tools::Netstring.encode("abc")
    assert_equal "3:abc,", s
  end

  def test_decode
    s, _ = Mail::Tools::Netstring.decode("3:abc,")
    assert_equal "abc", s
  end

  def test_decode_msg
    qmqp_string = "19:3:msg,2:rp,5:recip,,"
    msg, _ = Mail::Tools::Netstring.decode(qmqp_string)
    body, rp, *recip = Mail::Tools::Netstring::decode_list(msg)
    assert_equal "msg", body
    assert_equal "rp", rp
    assert_equal "recip", recip.first
  end

end
