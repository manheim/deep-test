module DeepTest
  module Distributed
    class LandingShip
      def initialize(config)
        @config = config
      end

      def push_code(options)
        RSync.push(@config[:address], options.sync_options, options.mirror_path)
      end

      def establish_beachhead(options)
        command  = "#{ssh_command(options)} '#{spawn_command(options)}' 2>&1"
        DeepTest.logger.debug { "Establishing Beachhead: #{command}" }

        output = `#{command}`
        output.split('\n').each do |line|
          if DeepTest.logger.level == Logger::DEBUG
            puts output
          end
          if line =~ /Beachhead port: (.+)/
            @wire = Telegraph::Wire.connect(@config[:address], $1.to_i)
          end
        end
        raise "LandingShip unable to establish Beachhead.  Output from #{@config[:address]} was:\n#{output}" unless @wire
      end

      def load_files(files)
        @wire.send_message Beachhead::LoadFiles.new(files)
      end

      def deploy_agents
        @wire.send_message Beachhead::DeployAgents
        begin
          message = @wire.next_message :timeout => 1
          raise "Unexpected message from Beachhead: #{message.inspect}" unless message.body == Beachhead::Done
        rescue Telegraph::NoMessageAvailable
          retry
        end
      end

      def ssh_command(options)
        username_option = if options.sync_options[:username]
                            " -l #{options.sync_options[:username]}"
                          else
                            ""
                          end

        "ssh -4 #{@config[:address]}#{username_option}"
      end

      def spawn_command(options)
        "#{ShellEnvironment.like_login} && " + 
        "cd #{options.mirror_path} && " +
        "OPTIONS=#{options.to_command_line} " + 
        "bundle exec ruby lib/deep_test/distributed/establish_beachhead.rb" 
      end
    end
  end
end
