module Mail
  module Tools
    # Sends message to a Spam Assasin service, returns a report object for inspection.
    # 
    # Usage:
    #   spam_client = Mail::Tools::SpamAssassin::Client.new(host, port, timeout)
    #   report = spam_client.check(rfc822_message_string)
    #   p report.inspect if report.spam?
    #
    # Credit: Adapted from https://github.com/noeticpenguin/RubySpamAssassin
    #   the RubySpamAssassin gem by Kevin Poorman
    
    module SpamAssassin
      class Result

        attr_accessor :response_version,
          :response_code,
          :response_message,
          :spam,
          :score,
          :threshold,
          :tags,
          :report,
          :content_length

        #returns true if the message was spam, otherwise false
        def spam?
          p [:spam, @spam]
          (@spam == "True" || @spam == "Yes") ? true : false
        end
      end

      class Client

        require 'socket'
        require 'timeout'

        def initialize(host=nil, port=nil, timeout=5)
          @host = host || ENV['SPAM_ASSASSIN_HOST'] || 'localhost'
          @port = port || ENV['SPAM_ASSASSIN_PORT'] || 783
          @timeout =timeout
          @socket = TCPSocket.open(@host, @port)
        end

        def check(message)
          if message.is_a?(Mail::Message)
            message = message.to_s
          elsif message.is_a?(Mail::Tools::Message)
            message = message.message
          end
          protocol_response = send_message("CHECK", message)
          process_headers protocol_response[0...2]
        end


        private
        def send_message(command, message)
          length = message.length
          @socket.write(command + " SPAMC/1.2\r\n")
          @socket.write("Content-length: " + length.to_s + "\r\n\r\n")
          @socket.write(message)
          @socket.shutdown(1) #have to shutdown sending side to get response
          response = @socket.readlines
          @socket.close #might as well close it now

          response
        end

        def process_headers(headers)
          result = Result.new
          headers.each do |line|
            case line.chomp
            when /(.+)\/(.+) (.+) (.+)/ then
              result.response_version = $2
              result.response_code = $3
              result.response_message = $4
            when /^Spam: (.+) ; (.+) . (.+)$/ then
              result.score = $2
              result.spam = $1
              result.threshold = $3
            when /Content-length: (.+)/ then
              result.content_length = $1
            end
          end
          result
        end
      end
    end
  end
end
