require_relative "../test/test_helpers"

class TestMailbox < MiniTest::Test

  def test_mail
    mailbox = "/tmp/Mailbox.test"
    File.unlink(mailbox) if File.exists?(mailbox)
    Mail::Tools::Mailbox.deliver(mailbox, basic_message)
    assert File.exist?(mailbox)
    f = File.read(mailbox)
    assert f =~ /\AFrom me@example.com/, "From line"
    assert f =~ /Delivered-To: you@example.com/m, "Delivered-To"
    assert f =~ /Subject: Testing/m, "Message Body"
    File.unlink(mailbox) if File.exists?(mailbox)
  end

  def test_each
    mailbox = "/tmp/Mailbox.test"
    File.unlink(mailbox) if File.exists?(mailbox)
    Mail::Tools::Mailbox.deliver(mailbox, basic_message)
    Mail::Tools::Mailbox.deliver(mailbox, basic_message)

    box = Mail::Tools::Mailbox.new(mailbox)
    assert_equal 2, box.count
    # Huh? .first returns an array below in test, not in irb. why?
    assert_match(/Subject/m, box.first.first.message)
    File.unlink(mailbox) if File.exists?(mailbox)
  end
end
