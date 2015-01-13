require_relative "../test/test_helpers"

class TestMailFile < MiniTest::Test
  TESTFILE = '/tmp/mail-tools-mailfile-test'

  def test_mailfile_write
    File.unlink(TESTFILE) if File.exists?(TESTFILE)
    Mail::Tools::MailFile.write(TESTFILE, basic_message)
    assert File.exists?(TESTFILE)
    d = File.read(TESTFILE)
    assert_equal d, "me@example.com\nyou@example.com\t{\"name\":\"You\"}\n\nSubject: Testing\nFrom: <me@example.com>\nTo: <you@example.com>\n\nTest Me!\n"
    File.unlink(TESTFILE) if File.exists?(TESTFILE)
  end

  def test_mailfile_read
    File.unlink(TESTFILE) if File.exists?(TESTFILE)
    Mail::Tools::MailFile.write(TESTFILE, basic_message)
    m = Mail::Tools::MailFile.read(TESTFILE)
    assert_equal m.return_path, 'me@example.com'
    assert_equal m.recipients.count, 1
    assert_match(/Subject/, m.message)
    File.unlink(TESTFILE) if File.exists?(TESTFILE)
  end

end
