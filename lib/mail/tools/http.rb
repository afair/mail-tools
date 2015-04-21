require 'net/http'

module Mail
  module Tools

    # Simulates SMTP over an HTTP call. Takes a mail tools message
    # and calls the URL with body parameters of mail_from, rcpt_to,
    # and message (data in SMTP parlance).
    #
    # It can also receive these parameters and construct a message
    # for the receiving side.
    class HTTP

      def self.deliver(mail_tools_message, url, options={})
        self.new(url, options).deliver(mail_tools_message)
      end

      def initialize(url, options={})
        @url      = url || ENV['MAILTOOLS_HTTP_URL']
        @options  = options
        @http_lib = options[:http_lib] || Net::HTTP
      end

      # Makes the HTTP Call, returns a MailTools::Result object
      def deliver(msg)
        begin
          # Authorization Header!!!
          request = (@options[:params] || {}).merge(
            {mail_from:msg.return_path,
             rcpt_to:  msg.recipients,
             message:  msg.message})

          @http_lib['Authorization'] = @options[:authorization] if @options[:authorization]
          res = @http_lib.post_form(URI(@url), request)
          {success:true, response:res.message, server:@url}
        rescue SocketError => e
          res = e
          {success:false, response:e.to_s, server:@url}
        end
      end

      def self.receive(params)
        Message.new(params['message'], params['mail_from'], params['rcpt_to'])
      end
    end
  end
end
