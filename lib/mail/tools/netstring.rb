module Mail
  module Tools

    # Returns the Netstring of the given string. It is defined at:
    #   http://cr.yp.to/proto/netstrings.txt
    # and is encoded as "<LENGTH>:<VALUE>,"
    #
    # Usage:
    #
    #   Mail::Tools::Netstring.of("mail-tools") #=> "10:mail-tools,"
    #
    # The Netstring is used mainly in QMQP Communications to encode
    # the message and envelope as:
    #
    #  netstring(netstring(messagebody) + netstring(returnpath)
    #            + netstring(recipient) + ...)
    #
    # Since SMTP is 7-bit only, this string is expected to be
    # a 7-bit ASCII. Unpredictable results will occur if you send
    # UTF-8 (Unicode) or 8-bit extensions (ISP-8851-x).

    class Netstring

      def self.valid?(str)
        len = str.to_i
        str =~ /\A\d+:(.{#{len}}),(.*)/m
      end

      def self.encode_message(msg)
        nstr  = encode(msg.message+"\n")
        nstr += encode(msg.return_path)
        msg.recipients.each { |r| nstr += Mail::Tools::Netstring.encode(r.address) }
        Mail::Tools::Netstring.encode(nstr)
      end

      def self.decode_message(netstring)
        qmqp_msg, _ = decode(netstring)
        body, rp, *recip = decode_list(qmqp_msg)
        Mail::Tools::Message.new(body, rp, recip)
      end

      # Encodes the given string as a netstring
      def self.encode(str)
        "#{str.size}:#{str},"
      end

      # Takes a netstring, returns a pair of the [string, remainder]
      # returns nil on a bad netstring format
      def self.decode(netstring)
        len = netstring.to_i
        if netstring && netstring =~ /\A\d+:(.{#{len}}),(.*)/m
          [$1, $2]
        else
          nil # bad String
        end
      end

      # Take a string containing concatenated netstrings, return array of
      # decoded strings
      def self.decode_list(list)
        strings = []
        while list
          s, list = decode(list)
          strings << s if s
        end
        strings
      end
    end
  end
end
