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
      attr_accessor :file, :message

      def initialize(filename, message=nil)
        @file = filename
        if File.exists?(filename)
          @message = self.read(@file)
        else
          @message = message || Mail::Tools::Message.new
        end
      end

      def write(message=nil)
        @message = message if nil
        save
      end

      def save
        MailFile.write(@file, @message)
      end

      def self.save(file, message)
        mf = ::MAil::Tools::MailFile.new(file, message)
        mf.save
        mf
      end

      # Loads message from a Mailfile, returns a Mail::Tools::Message object
      def self.read(filename)
        msg = Mail::Tools::Message.new
        File.open(filename) do |f|
          while (rec = f.readline.chomp) > ""
            if msg.return_path_empty?
              msg.return_path = rec
            else
              msg.recipients.add(rec)
            end
          end
          msg.message = f.read.chomp
        end
        msg
      end

      # Takes a MailTools::Message and a target path and filename. Serializes the
      # message to the given filename
      def self.write(filename, msg)
        File.open(filename, 'w') do |f|
          f.puts msg.return_path
          msg.recipients.each { |r| 
            f.puts r.to_record 
          }
          f.puts "\n" + msg.message
        end
        File.exist?(filename)
      end

    end
  end
end
