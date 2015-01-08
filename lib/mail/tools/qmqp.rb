module Mail
  module Tools

    # Transfers a message to another mail server using Mail::Tools's QMQP protocol.
    #   http://cr.yp.to/proto/qmqp.html
    #
    # This is not intended as a delivery transport. It transfers the message
    # as a queue object (message, return path, recipients) to another server
    # for delivery. The remote server runs a "mail_tools-qmqpd" daemon to accept
    # the message. Postfix also ships with a QMQP listener so can be used as
    # the target MTA.
    #
    # Usage:
    #
    #   Mail::Tools::QMQP.deliver(mail_tools_message)
    #
    # Returns: Hash of the following:
    #
    #   {sucess:boolean, response:string, server:"ip:port"}
    #
    class QMQP

      def self.deliver(msg, options={})
        QMQP.new(options).deliver(msg)
      end

      def initialize(options={})
        @options = options
      end

      def deliver(mail_tools_message=nil)
        msg    = mail_tools_message if mail_tools_message
        begin
          ip     = @options[:ip]   || qmqp_server
          port   = @options[:port] || Mail::Tools::Config.qmqp_port
          socket = TCPSocket.new(ip, port)
          if socket
            socket.send(msg.to_netstring, 0)
            socket.close_write
            @response = socket.recv(1000)
          end
          socket.close
          {sucess:true, response:@response, server:"#{ip}:#{port}"}

        rescue SocketError, SystemCallError => e
          socket.close if socket
          {sucess:false, response:e.to_s, server:"#{ip}:#{port}"}
        end
      end

      # Returns the configured QMQP server ip address
      def qmqp_server(i=0)
        return @options[:qmqp_server] if @options[:qmqp_server]
        dir = @options[:dir] || '/var/qmail'
        filename = "#{dir}/control/qmqpservers"
        return '127.0.0.1' unless File.exists?(filename)
        File.readlines(filename)[i].chomp
      end

      # Takes a socket with an incoming qmqp message, returns the message
      def self.receive(io)
        b = ''
        while (ch = io.read(1)) =~ /\d/
          b += ch
        end
        msg = io.read(b.to_i)
        message = Message.from_netstring("#{b}:" + msg + ',')

        if message
          io.puts Mail::Tools::Netstring.encode("Kok #{Time.now.to_i} qp #{$$}")
        else
          io.puts Mail::Tools::Netstring.encode("DError in message")
        end

        message
      end

      # Simple server, for prototyping
      # Mail::Tools::QMQP::Server.new() { |msg| p msg }
      class Server
        def initialize(bind_ip='127.0.0.1', port=630, max_accepts=-1, &block)
          begin
            server = TCPServer.new(bind_ip, port)
            while max_accepts != 0
              Thread.start(server.accept) do |client|
                msg = receive(client)
                client.close
                yield msg if msg
                max_accepts -= 1
              end
            end
          rescue Exception => e
            puts "Exception! #{e}"
          end
        end
      end
    end

  end
end
