module DeepTest
  class Warlock
    def self.demon_pipes
      @@pipes ||= {}
    end

    def initialize(options)
      @options = options
      @demons_semaphore = Mutex.new
      @demons = []
      @reapers = []
    end

    def start(name, demon, *demon_args)
      # Not synchronizing for the fork seems to cause
      # random errors (Bus Error, Segfault, and GC non-object)
      # in Beachhead processes.
      #
      begin
        pid = nil
        @demons_semaphore.synchronize do
          pid = fork do
            # Fork leaves the semaphore locked and we'll never make it
            # to end of synchronize block.
            #
            # The Ruby 1.8.6 C mutex implementation automatically treats
            # a mutex locked by a dead thread as unlocked and will raise
            # an error if we try to unlock it from this thread.
            #
            @demons_semaphore.unlock if @demons_semaphore.locked?

            close_open_network_connections
            # When forking processes, pipes are duplicated.  If a pipe is not closed
            # correctly in all child processes, the parent process can not read from
            # it.
            close_duplicated_pipes name
            demon.forked name, @options, demon_args

            exit
          end

          raise "fatal: fork returned nil" if pid.nil?
          add_demon name, pid
        end

        launch_reaper_thread name, pid

      rescue => e
        puts "exception starting #{name}: #{e}"
        puts "\t" + e.backtrace.join("\n\t")
      end
    end

    def close_open_network_connections
      ObjectSpace.each_object(BasicSocket) do |sock|
        begin
          sock.close
        rescue IOError
        end
      end
    end

    def close_duplicated_pipes current_name
      Warlock.demon_pipes.each do |demon_name,pipes|
        input,output = pipes
        output.close if (!output.closed? && demon_name != current_name)
        input.close if (!input.closed? && demon_name != current_name)
      end
    end

    def demon_count
      @demons_semaphore.synchronize do
        @demons.size
      end
    end

    def stop_demons
      DeepTest.logger.debug { "stopping all demons" }
      receivers = @demons_semaphore.synchronize do
        @demons.reverse
      end

      receivers.reverse.each do |demon|
        name, pid = demon
        if running?(pid)
          DeepTest.logger.debug { "Sending SIGTERM to #{name}, #{pid}" }
          Process.kill("TERM", pid)
        end
      end
      DeepTest.logger.debug { "Warlock: Stopped all receivers" }

      DeepTest.logger.debug { "waiting for reapers" }
      @reapers.each {|r| r.join}

      DeepTest.logger.debug { "Warlock: done reaping processes" }
    end

    def exit_when_none_running
      Thread.new do
        wait_for_all_to_finish
        DeepTest.logger.debug { "exiting #{Process.pid} with all demons finished" }
        exit(0)
      end
    end

    def wait_for_all_to_finish
      loop do
        Thread.pass
        return unless any_running?
        sleep(0.01)
      end
    end

    def any_running?
      @demons_semaphore.synchronize do
        @demons.any? {|name, pid| running?(pid)}
      end
    end

    #stolen from daemons
    def running?(pid)
      # Check if process is in existence
      # The simplest way to do this is to send signal '0'
      # (which is a single system call) that doesn't actually
      # send a signal
      begin
        Process.kill(0, pid)
        return true
      rescue Errno::ESRCH
        return false
      rescue ::Exception   # for example on EPERM (process exists but does not belong to us)
        return true
      #rescue Errno::EPERM
      #  return false
      end
    end

    protected

    def add_demon(name, pid)
      DeepTest.logger.debug { "Started: #{name} (#{pid})" }
      @demons << [name, pid]
    end

    def remove_demon(name, pid)
      @demons.delete [name, pid]
      DeepTest.logger.debug { "Stopped: #{name} (#{pid})" }
    end


    def launch_reaper_thread(name, pid)
      @reapers << Thread.new do
        Process.detach(pid).join
        DeepTest.logger.debug { "#{name} (#{pid}) reaped" }
        @demons_semaphore.synchronize do
          DeepTest.logger.debug { "Warlock Reaper: removing #{name} (#{pid}) from demon list" }
          remove_demon name, pid
        end
      end
    end
  end
end
