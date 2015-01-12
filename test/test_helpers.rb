require 'rubygems'
require 'minitest/autorun'
require 'minitest/pride'
require 'mail/tools'

MAILDROP_DIR = "/tmp/mail-tools-maildrop"

def basic_email
    "Subject: Testing\nFrom: <me@example.com>\nTo: <you@example.com>\n\nTest Me!"
end

def basic_message(from=ENV['FROM'], to=ENV['TO'], opt={})
    Mail::Tools::Message.new(basic_email, from||'me@example.com', to||'you@example.com')
end

def maildrop
    Dir.mkdir(MAILDROP_DIR) unless Dir.exist?(MAILDROP_DIR)
      Mail::Tools::Maildrop.new(MAILDROP_DIR)
end
