module Mail
  module Tools

    # Transfers a message to another mail server using Mail::Tools's QMQP protocol.
    #   http://cr.yp.to/proto/qmqp.html
    #
    # This is not intended as a delivery transport. It transfers the message
    # as a queue object (message, return path, recipients) to another server
    # for delivery. The remote server runs a "qmail-qmqpd" daemon to accept
    # the message. Postfix also ships with a QMQP listener so can be used as
    # the target MTA.
    #
    # Usage:
    #
    #   Mail::Tools::QMQP.deliver(message, ip:address, port:628)
    #
    #   Server IP Address can be configured as a single ip address, or a
    #   comma-delimited list, found in the following priority:
    #   * as :ip in options hash as a string or array of IP strings
    #   * QMQP_SERVERS environment variable
    #   * Qmail qmqpservers (/var/qmail/configure/qmqpservers)
    #   * Default of 127.0.0.1
    #   Each address can be of the format "ip:port" to override the port.
    #
    # Returns: Hash of the following:
    #
    #   {sucess:boolean, response:string, server:"ip:port"}
    #
    class QMQP
      QMAIL_QMQPSERVERS='/var/qmail/configure/qmqpservers'

      def self.deliver(msg, options={})
        Mail::Tools::QMQP.new(options).deliver(msg)
      end

      def initialize(options={})
        @options = options
        if @options[:ip]
          @options[:ip] = @options[:ip].split(",") if @options[:ip].is_a?(String)
        elsif ENV['QMQP_SERVERS']
          @options[:ip] = ENV['QMQP_SERVERS'].split(",")
        elsif File.exists?(QMAIL_QMQPSERVERS)
          @options[:ip] = File.read(QMAIL_QMQPSERVERS).split("\n")
        else
          @options[:ip] = ['127.0.0.1']
        end
      end

      # Delivers
      def deliver(message)
        socket = connect_to_server
        if socket
          socket.send(Mail::Tools::Netstring.encode_message(message), 0)
          socket.close_write
          @response = socket.recv(1000)
          if Mail::Tools::Netstring.valid?(@response)
            @response, _ = Mail::Tools::Netstring.decode(@response)
          end
          socket.close
          {success:true, response:@response, server:"#{@ip}:#{@port}"}
        else
          {success:false, response:@errors.join("\n")}
        end
      end

      # Connect to first avail server in qmqpservers list, returns socket
      def connect_to_server
        ips  = Array(@options[:ip])
        ips  = ips.shuffle if @options[:shuffle]
        port = @options[:port] || 628
        @errors = []
        ips.each do |ip|
          begin
            @ip, @port = ip.split(':')
            @port ||= port
            socket = TCPSocket.new(@ip, @port)
          rescue SocketError, SystemCallError => e
            @errors << "QMQP Connect Error [#{ip}:#{port}]: #{e}"
          end
          return socket if socket
        end
        nil
      end

      # Returns the configured QMQP server ip address
      def qmqp_server(i=0)
        return @options[:qmqp_server] if @options[:qmqp_server]
        dir = @options[:dir] || '/var/qmail'
        filename = "#{dir}/control/qmqpservers"
        return '127.0.0.1' unless File.exists?(filename)
        File.readlines(filename)[i].chomp
      end

      # A simple, reference implementation QMQP Daemon server.
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

        # Takes a socket with an incoming qmqp message, returns the message
        def receive(io)
          b = ''
          while (ch = io.read(1)) =~ /\d/
            b += ch
          end
          msg = io.read(b.to_i)
          message = Mail::Tools::Netstring.decode_message("#{b}:" + msg + ',')

          if message
            io.puts Mail::Tools::Netstring.encode("Kok #{Time.now.to_i} qp #{$$}")
          else
            io.puts Mail::Tools::Netstring.encode("DError in message")
          end

          message
        end
      end

    end

  end
end
