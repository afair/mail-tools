# Mail::Tools

Provides Mail email message handling extensions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mail-tools'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mail-tools

## Usage

TODO: Write usage instructions here

## HMTP: Hypertext Mail Transport Protocol (Message Delivery over HTTP)

    https://mail.example.com/
    POST /
    Content-Type: application/x-www-form-urlencoded
    Accept: application/json
    HMTP-Helo: outgoing.example.com
    HMTP-Mail-From: sender@example.com
    HMTP-Rcpt-To: recipient1@example.com
    HMTP-Rcpt-To: recipient2@example.com
    HMTP-Message-Id: <Token>

    Subject: Your Message...

    https://mail.example.com/
    POST /
    Content-Type: application/x-www-form-urlencoded
    Accept: application/json

    HELO=outgoing.example.com
    MAIL_FROM=sender@example.com
    RCPT_TO=recipient1@example.com
    RCPT_TO=recipient2@example.com
    DATA=Subject: Your Message...

    HELO=250 Hello relay.example.org
    MAIL_FROM=250 Ok
    RCPT_TO=250 Ok
    DATA=200 Ok: queued as 12345
    QUIT=221 Bye
    ID=<Token>

    https://outgoing.example.com/
    GET /<Message-MD5>/<Recipient-MD5>

    MAIL_FROM=<Sender-MD5>
    DATA=<Data-MD5>

    https://outgoing.example.com/
    DELETE /<Message-Id>/<Recipient-MD5>

    RCPT_TO=<Recipient-MD5>
    REASON=0.0.0 Bounce Message
    DATA=<Data-MD5>

    https://outgoing.example.com/
    <DELETE|POST> /<Message-Id>/<Recipient-MD5>/<action>

    Action: unsubscribe, complain, confirm, redact, <frequency>

Relay Standard

    http://relay.example.com
    POST /
    Authorization: <Token>
    HMTP-Mail-From: sender@example.com
    HMTP-Rcpt-To: recipient1@example.com
    HMTP-Rcpt-To: recipient2@example.com
    HMTP-Message-Id: <Token>

    Subject: Your Message...

Receiving Decomposed Mail

    http://relay.example.com
    POST /
    Authorization: <Token>
    HMTP-Mail-From: sender@example.com
    HMTP-Rcpt-To: recipient1@example.com
    HMTP-Message-Id: <Token>

    subject=...
    from=header
    from_email=info@example.com
    to=header
    to_email=recipient1@example.com
    subject:Hello!
    date=...
    text:Howdy
    html:<div>howdy</div>
    Attachments as multipart upload...

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mail-tools/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
