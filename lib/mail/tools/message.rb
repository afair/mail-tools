require 'digest/md5'
require 'json'

module Mail
  module Tools

    # The Mail::Tools::Message is a Mail delivery object. It consists of:
    # 
    #   * Message     - The email message to be delivered
    #   * Return Path - The "envelope" from or "bounce back" email address
    #   * Recipients  - The list of email addresses and optional hash of
    #                   mail-merge name/value pairs
    #
    # The Message object can be passed around the Mail::Tools library
    class Message
      attr_accessor :message, :return_path, :recipients

      # Message.new("message", "return_path@example.com", "recip1@example.com", ...., {option:value})
      def initialize(*args)
        self.message     = args.shift
        self.return_path = args.shift
        self.recipients  = args
      end

      ##########################################################################
      # Message
      ##########################################################################
      # The email message can be one of the following:
      #   * String of RFC822 email message
      #   * Mail object of message
      #   * Hash of parameters to Editor.construct()
      #   * Anything else results in an empty message
      def message=(obj)
        case obj
        when String
          @message = obj
        when Mail
          @mail    = obj
          @message = Mail.to_s
        when Hash
          @mail    = Mail::Tools::Editor.construct(obj)
          @message = @mail.to_s
        else
          @message = ''
        end
      end

      def mail
        @mail ||= Mail.new(self.message)
      end

      def editor
        @editor ||= Mail::Tools::Editor.for_mail(self.mail)
      end

      # Yields an editor object to a block, refreshes internal message
      # after it returns.
      def edit
        yield @editor
        @mail = @editor.mail
        @message = @mail.to_s
      end

      ##########################################################################
      # Envelope Return Path (From) Email Address
      # - Defines where undeliverable email reports will be mailed
      # - Tracks the VERP (Variable Envelope Return Path) for the message
      #   * Format: local-@host-@[]
      #   * Result: local-recipient=reciphost@host
      ##########################################################################
      # The return path can be of the following formats:
      #   * local@example.com - Standard Email Address
      #   * local-@example.com-@[] - VERP-enabled email address
      #   * Uses the "From" header in the message if nil
      #   * Otherwise uses the standard blank "<>" address
      VERP_FLAG = '-@[]'

      def return_path=(rp)
        if rp.is_a?(String)
          @return_path = rp
        else
          @return_path = editor.from_email || '<>'
        end
      end

      # Enable VERP on the delivery
      def verp!
        return true  if self.verp?
        @return_path.sub!('@', '-@')
        @return_path += VERP_FLAG
        true
      end

      def verp_off!
        return false unless self.verp?
        @return_path.sub!('-@', '@')
        @return_path.sub!(VERP_FLAG,'')
      end

      def verp?
        @return_path && @return_path.end_with?(VERP_FLAG)
      end
      
      ##########################################################################
      # Recipients
      ##########################################################################
      # See Mail::Tools::Recipients for the complete format of parameters:
      # Takes recipients from the To/CC/BCC headers if the argument is:
      #   self.recipients = :headers
      #
      # Otherwise, takes an array of mixed types for a recipient
      #   * Email Address
      #   * Recipient (Email Address, Mail-Merge Data Hash)
      #   * Text lines of "email address <JSON_DATA>\n..."
      #   * Hash of {"pat@example.com"=>{name:"Pat"}, ...}
      #   * JSON representation of above Hash
      #   * File object
      #   * Any enumerable object returning one of the above on each()
      def recipients=(recip_array)
        if recip_array.is_a?(Symbol) && recip_array == :headers
          self.recipients_from_headers
        else
          @recipients = Mail::Tools::Recipients.coerce(*recip_array)
        end
      end

      def recipients_from_headers
        @recipients = Mail::Tools::Recipients.new
        [:to, :cc, :bcc].each do |h|
          mail[h].addrs.each {|a| @recipients.add(a) }
        end
        edit { |e| e.delete_header(:bcc) }
        @recipients
      end

    end
  end
end
