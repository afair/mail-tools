module Mail
  module Tools

    # A MailFile is a standard text file format to hold a delivery
    # message, containing its envelope (sender, recipients) and body.
    #
    # Format: Return path, recipients, blank line, RFC822 Message
    #   The recipient line can conatin merge-data as well.
    #
    #-----------------------------------------------------------------
    #   bounces@example.com
    #   pat@example.com  {"name":"Pat"}
    #   info@example.com
    #
    #   Subject: Message
    #   From: <sender@example.com>
    #   To: <recipient@example.com>
    #
    #   Hello, World
    #-----------------------------------------------------------------

    class MailFile

      # Loads message from a Mailfile, returns a Mail::Tools::Message object
      def self.read(filename)
        msg = Mail::Tools::Message.new
        File.open(filename) do |f|
          while (rec = f.readline.chomp) > ""
            if rec =~ /\AMailfile (.+)/
              msg.options = parse_options($1)
            elsif msg.return_path.nil? || msg.return_path == ""
              msg.return_path = rec
            else
              msg.recipients.push(rec)
            end
          end
          msg.message = f.read.chomp
        end
        msg
      end

      # Takes a MailTools::Message and a target path and filename. Serializes the
      # message to the given filename
      def self.write(filename, msg)
        begin
          File.open(filename, 'w') do |f|
            f.puts msg.return_path
            msg.recipients.each { |r| f.puts r }
            f.puts "\n" + msg.message
          end
        rescue
        end
        File.exist?(filename)
      end

    end
  end
end
