require_relative '../test/test_helpers'
require 'webrick'

class TestHTTP < MiniTest::Test

  def setup
    run_http_server
  end

  def teardown
    @server.shutdown
  end

  def test_deliver
    r = Mail::Tools::HTTP.deliver(basic_message, "http://localhost:3957/")
    assert r[:success]
    assert_equal "me@example.com", @message.return_path
  end

  def test_http_failure
    r = Mail::Tools::HTTP.deliver(basic_message, "http://gk48t5jhgy7.com/bad/")
    assert_equal r[:success], false
  end

  def run_http_server
    @message = nil
    log_file = File.open '/dev/null', 'a+'
    log = WEBrick::Log.new log_file
    @server = WEBrick::HTTPServer.new(:Port=>3957, :Logger=>log, :AccessLog=>log)

    Thread.new do
      @server.mount_proc '/' do |req, res|
        @message = Mail::Tools::HTTP.receive(req.query)
        res.body = 'Accepted!'
      end
      trap 'INT' do @server.shutdown end
      @server.start
    end
  end
end
