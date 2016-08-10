module DeepTest
  module Distributed
    class NoOpenPorts < StandardError
      def initialize
        super "No ports open between #{MIN_PORT} and #{MAX_PORT}"
      end
    end

    class Beachhead < LocalDeployment
      include Demon

      MIN_PORT = 62432
      MAX_PORT = 62532
      PORT_RANGE = *MIN_PORT..MAX_PORT

      MERCY_KILLING_GRACE_PERIOD = 10 * 60 unless defined?(MERCY_KILLING_GRACE_PERIOD)

      def initialize(base_path, options)
        super options
        @base_path = base_path
      end

      def launch_mercy_killer(grace_period)
        Thread.new do
          sleep grace_period
          exit(0) unless agents_deployed?
        end
      end

      def load_files(files)
        spec_support_path = File.expand_path(File.dirname(__FILE__) + "/../spec") 
        Dir.chdir @base_path
        resolver = FilenameResolver.new(@base_path)
        files.each do |file|
          load resolver.resolve(file)
        end

        # Load rspec support if rspec is available now that we've loaded the host project files
        #
        DeepTest::RSpecDetector.if_rspec_available do
          require spec_support_path
        end
      end

      def deploy_agents
        @agents_deployed = true
        super
        warlock.exit_when_none_running
      end

      def agents_deployed?
        @agents_deployed
      end

      def forked(*args)
        $stdout.reopen("/dev/null")
        $stderr.reopen("/dev/null")
        super
      end

      def execute(innie, outie, grace_period)
        innie.close

        switchboard = Telegraph::Switchboard.new
        operator = setup_listener(switchboard)

        DeepTest.logger.debug { "Beachhead started on port #{operator.port}" }

        outie.write operator.port
        outie.close

        launch_mercy_killer grace_period

        loop do
          begin
            switchboard.process_messages :timeout => 1 do |message, wire|
              case message.body
              when LoadFiles
                load_files message.body.files
              when DeployAgents
                deploy_agents
                wire.send_message Done
                operator.shutdown
                break
              end
            end
          end
        end
      end

      def setup_listener(switchboard)
        connection_attempt = 1
        begin
          port = PORT_RANGE[connection_attempt - 1]
          raise NoOpenPorts if port.nil?
          Telegraph::Operator.listen "0.0.0.0", port, switchboard
        rescue Errno::EADDRINUSE
          connection_attempt += 1
          retry
        end
      end

      def daemonize(grace_period = MERCY_KILLING_GRACE_PERIOD)
        innie, outie = IO.pipe

        warlock.start "Beachhead", self, innie, outie, grace_period

        outie.close
        port = innie.gets
        innie.close
        port.to_i
      end

      unless defined? DeployAgents
        DeployAgents = "DeployAgents"
        Done = "Done"
        class LoadFiles
          attr_reader :files
          def initialize(files)
            @files = files
          end
        end
      end
    end
  end
end
