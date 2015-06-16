module DeepTest
  module Demon
    def forked(name, options, demon_args)
      options.connect_to_central_command do |wire|
        ProxyIO.replace_stdout_stderr!(wire) do
          begin
            execute(*demon_args)
          rescue SystemExit => e
            raise
          rescue Exception => e
            FailureMessage.show self.class.name, "Process #{Process.pid}, connected to #{Socket.gethostname}, exiting with exception: #{e.class}: #{e.message}"
            raise
          end
        end
      end
    end

    def execute(*args)
      raise "#{self.class} must implement the execute method to be a Demon"
    end
  end
end
