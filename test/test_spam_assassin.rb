require_relative "../test/test_helpers"

class TestQMQP < MiniTest::Test

  def test_scan
    unless ENV['SPAM_ASSASSIN_HOST']
      puts "Skipping Spam Assassin testing. set SPAM_ASSASSIN_HOST"
      return
    end
    report = Mail::Tools::SpamAssassin::Client.new.check(basic_email)
    p report
    assert_equal false, report.spam?
  end

end
