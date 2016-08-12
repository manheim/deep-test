require 'thread'

module Telegraph
  class NoOpenPorts < StandardError
    def initialize
      super "No ports open between #{MIN_PORT} and #{MAX_PORT}"
    end
  end

  class Operator
    include Logging

    MIN_PORT = 62430
    MAX_PORT = 62539
    PORT_RANGE = *MIN_PORT..MAX_PORT

    attr_reader :switchboard

    def self.listen(host, switchboard = Switchboard.new)
      connection_attempt = 0

      begin
        port = MIN_PORT + connection_attempt
        raise NoOpenPorts if port > MAX_PORT
        server = TCPServer.new(host, port)
      rescue Errno::EADDRINUSE
        connection_attempt += 1
        retry
      end

      new(server, switchboard)
    end

    def initialize(socket, switchboard)
      @socket = socket
      @switchboard = switchboard
      @accept_thread = Thread.new do
        @socket.listen 100
        loop do
          if @should_shutdown
            @socket.close
            @switchboard.close_all_wires
            break
          end

          begin
            client = @socket.accept_nonblock
            debug { "Accepted connection: #{client.inspect}" }
            @switchboard.add_wire Wire.new(client)
          rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
            connection_ready, = IO.select([@socket], nil, nil, 0.25)
            retry if connection_ready
          end
        end
      end
    end

    def port
      @socket.addr[1]
    end

    def shutdown
      debug { "Shutting down" }
      @should_shutdown = true
      @accept_thread.join
    end
  end
end
