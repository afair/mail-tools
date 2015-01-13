require_relative "../test/test_helpers"

class Testeditor < MiniTest::Test

  def test_new
    e = Mail::Tools::Editor.new(basic_email)
    assert e.subject, 'Testing'

    e = Mail::Tools::Editor.new(basic_message)
    e = Mail.new(basic_email)
    assert e.subject, 'Testing'

    e = Mail::Tools::Editor.new(Mail.new(basic_email))
    assert e.subject, 'Testing'
  end

  def test_construct
    e = Mail::Tools::Editor.construct(
          subject: "Testing",
          from: "info@example.com", from_name: "Information",
          to:   "pat@example.com",  to_name:   "Pat", # Single recipient
          body_text: "Hello!",
          body_html: "<h1>Hello!</h1>")
    assert_equal e.subject, 'Testing'
    assert_equal e[:from], 'Information <info@example.com>'
    assert_equal e[:to], 'Pat <pat@example.com>'
    assert_equal e.text, 'Hello!'
  end

  def test_headers
    e = Mail::Tools::Editor.new(basic_email)
    e.set_header('Delivered-To', 'me')
    assert_equal e[:delivered_to], 'me'
    e.delete_header('Delivered-To')
    assert_equal e[:delivered_to], nil
  end

end
