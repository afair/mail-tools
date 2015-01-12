require_relative "../test/test_helpers"

class TestQMQP < MiniTest::Test

  def run_qmqp_server
    @qmqpmsg = nil
    Thread.new do
      Mail::Tools::QMQP::Server.new('127.0.0.1', 6280, 1) do |msg|
        @qmqpmsg = msg
      end
    end
  end

  def test_qmqp
    m = basic_message
    run_qmqp_server
    r = Mail::Tools::QMQP.new(ip:'127.0.0.1', port:6280).deliver(m)
    #p [:qmqp_result, r] unless r.succeeded?
    assert r[:success], true
    assert_equal m.message, @qmqpmsg.message.chomp # qmqp adds \n
  end

end
