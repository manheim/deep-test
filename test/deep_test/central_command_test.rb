require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

module DeepTest
  unit_tests do
    test "take_work returns result of push_work when it is available" do
      central_command = CentralCommand.new Options.new({})
      central_command.write_work :work
      assert_equal :work, central_command.take_work
    end

    test "take_work raises error when no work is currently available" do
      assert_raises(CentralCommand::NoWorkUnitsAvailableError) do
        CentralCommand.new(Options.new({})).take_work
      end
    end

    test "take_work raises error when there is no work left to" do
      central_command = CentralCommand.new Options.new({})
      central_command.done_with_work

      assert_raises(CentralCommand::NoWorkUnitsRemainingError) do
        central_command.take_work
      end
    end

    test "take_result raises NoAgentsRunningError if agents are connected" do
      central_command = CentralCommand.start Options.new({}) 
      DynamicTeardown.on_teardown { central_command.stop }
      assert_raises(CentralCommand::NoAgentsRunningError) {central_command.take_result}
    end

    test "start returns instance of central_command" do
      central_command = CentralCommand.start Options.new({})
      DynamicTeardown.on_teardown { central_command.stop }
      assert_kind_of CentralCommand, central_command
    end

    test "after starting CentralCommand responds to NeedWork messages by supplying new units of work" do
      central_command = CentralCommand.start(options = Options.new({}))
      DynamicTeardown.on_teardown { central_command.stop }
      central_command.write_work(:a)
      central_command.write_work(:b)
      central_command.write_work(:c)

      wire = Telegraph::Wire.connect("localhost", options.server_port)
      after_connecting_to central_command do
        [:a, :b, :c].each do |work_unit|
          Thread.pass
          wire.send_message CentralCommand::NeedWork
          assert_equal work_unit, wire.next_message(:timeout => 2.0).body
        end
      end
    end

    test "after starting CentralCommand responds to Result messages adding results to the queue" do
      central_command = CentralCommand.start(options = Options.new({}))
      DynamicTeardown.on_teardown { central_command.stop }
      wire = Telegraph::Wire.connect("localhost", options.server_port)
      result_1, result_2, result_3 = TestResult.new(1), TestResult.new(2), TestResult.new(3)

      [result_1, result_2, result_3].each do |result|
        wire.send_message result
      end

      after_connecting_to central_command do
        assert_equal result_1, central_command.take_result
        assert_equal result_2, central_command.take_result
        assert_equal result_3, central_command.take_result
      end
    end

    test "after starting CentralCommand responds to Result by supplying a new unit of work" do
      central_command = CentralCommand.start(options = Options.new({}))
      DynamicTeardown.on_teardown { central_command.stop }
      central_command.write_work(:a)
      central_command.write_work(:b)
      central_command.write_work(:c)

      wire = Telegraph::Wire.connect("localhost", options.server_port)

      after_connecting_to central_command do
        result_1, result_2, result_3 = TestResult.new(1), TestResult.new(2), TestResult.new(3)
        [[result_1, :a], [result_2, :b], [result_3, :c]].each do |result, work_unit|
          Thread.pass
          wire.send_message result_1
          assert_equal work_unit, wire.next_message(:timeout => 2.0).body
        end
      end
    end

    test "will add results to queue with a worker waiting for work that is not available" do
      central_command = CentralCommand.start(options = Options.new({}))
      DynamicTeardown.on_teardown { central_command.stop }

      Telegraph::Wire.connect("localhost", options.server_port) do |wire|
        wire.send_message CentralCommand::NeedWork
        wire.send_message TestResult.new(1)
      end

      after_connecting_to central_command do
        assert_equal TestResult.new(1), central_command.take_result
      end
    end

    test "will distribute work units that have not received results from dead workers when other work runs out" do
      central_command = CentralCommand.start(options = Options.new({}))
      DynamicTeardown.on_teardown { central_command.stop }

      central_command.write_work(:a)

      Telegraph::Wire.connect("localhost", options.server_port) do |wire|
        wire.send_message CentralCommand::NeedWork
        after_connecting_to central_command do
          assert_equal :a, wire.next_message(:timeout => 1).body
        end
      end

      Telegraph::Wire.connect("localhost", options.server_port) do |wire|
        wire.send_message CentralCommand::NeedWork
        after_connecting_to central_command do
          assert_equal :a, wire.next_message(:timeout => 1).body
        end
      end
    end

    test "will add measurements to data when received over the wire" do
      central_command = CentralCommand.start(options = Options.new({}))
      DynamicTeardown.on_teardown { central_command.stop }

      Telegraph::Wire.connect("localhost", options.server_port) do |wire|
        wire.send_message Metrics::Measurement.new("category", 1, "units")
      end

      after_connecting_to central_command do
        sleep 0.05
        assert_match /category: 1.0 avg/, central_command.data.summary
      end
    end

    class SetCalledGlobalToTrue
      include CentralCommand::Operation
      def execute; $called = true; end
    end

    test "will execute Operations read from the wire" do
      $called = false
      DynamicTeardown.on_teardown { $called = nil }
      central_command = CentralCommand.start(options = Options.new({}))
      DynamicTeardown.on_teardown { central_command.stop }
      wire = Telegraph::Wire.connect("localhost", options.server_port)
      wire.send_message SetCalledGlobalToTrue.new

      Timeout.timeout(2) do
        loop do
          break if $called
          sleep 0.25
        end
      end
    end

    def after_connecting_to central_command, timeout = 5
      start = Time.now
      timedout = false
      until central_command.instance_variable_get('@switchboard').any_live_wires? || timedout
        timedout = (Time.now - start) > timeout
      end
      raise "Timed out connection to central command in tests" if timedout
      yield
    end
  end
end
