require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

module DeepTest

  unit_tests do
    test "puts result on central_command with acknowledgement of work" do
      options = Options.new({})
      central_command = TestCentralCommand.start options
      central_command.write_work Test::WorkUnit.new(TestFactory.passing_test)
      central_command.done_with_work

      Agent.new(0, options, stub_everything).execute(StringIO.new, StringIO.new)

      assert_equal [], central_command.switchboard.live_wires.first.unacked_messages
      assert_kind_of ::Test::Unit::TestResult, central_command.take_result
    end

    test "puts passing and failing tests on central_command for each test" do
      options = Options.new({})
      central_command = TestCentralCommand.start options
      central_command.write_work Test::WorkUnit.new(TestFactory.passing_test)
      central_command.write_work Test::WorkUnit.new(TestFactory.failing_test)
      central_command.done_with_work

      Agent.new(0, options, stub_everything).execute(StringIO.new, StringIO.new)

      result_1 = central_command.take_result
      result_2 = central_command.take_result

      assert_equal true, (result_1.passed? || result_2.passed?)
      assert_equal false, (result_1.passed? && result_2.passed?)
    end

    test "notifies listener that it is starting" do
      options = Options.new({})
      central_command = TestCentralCommand.start options
      central_command.done_with_work
      listener = stub_everything
      agent = Agent.new(0, options, listener)
      listener.expects(:starting).with(agent)
      agent.execute(StringIO.new, StringIO.new)
    end

    test "notifies listener that it is about to do work" do
      options = Options.new({})
      central_command = TestCentralCommand.start options
      work_unit = Test::WorkUnit.new(TestFactory.passing_test)
      central_command.write_work work_unit
      central_command.done_with_work
      listener = stub_everything
      agent = Agent.new(0, options, listener)
      listener.expects(:starting_work).with(agent, work_unit)
      agent.execute(StringIO.new, StringIO.new)
    end

    test "notifies listener that it has done work" do
      options = Options.new({})
      central_command = TestCentralCommand.start(options)
      work_unit = ResultWorkUnit.new(:result)
      central_command.write_work work_unit
      central_command.done_with_work
      listener = stub_everything
      agent = Agent.new(0, options, listener)
      listener.expects(:finished_work).with(agent, work_unit, TestResult.new(:result))
      agent.execute(StringIO.new, StringIO.new)
    end

    test "notifies listener that it is ending" do
      options = Options.new({})
      central_command = TestCentralCommand.start(options)
      work_unit = ResultWorkUnit.new(:result)
      central_command.write_work work_unit
      central_command.done_with_work
      listener = stub_everything
      agent = Agent.new(0, options, listener)
      listener.expects(:ending).with(agent)
      agent.execute(StringIO.new, StringIO.new)
    end

    test "connect indicates it has connected" do
      options = Options.new({})
      central_command = TestCentralCommand.start(options)
      agent = Agent.new(0, options, stub_everything)
      yielded = false
      agent.connect(io = StringIO.new) do
        yielded = true
        assert_equal "Connected\n", io.string
        assert_equal true, io.closed?
      end
      assert yielded, "connect didn't yield"
    end

    test "connect closes stream even if there is an error" do
      options = Options.new({})
      agent = Agent.new(0, options, stub_everything)
      io = StringIO.new
      assert_raises(Errno::EADDRNOTAVAIL, Errno::ECONNREFUSED) { agent.connect io }
      assert_equal true, io.closed?
    end

    class ResultWorkUnit
      attr_reader :result

      def initialize(result)
        @result = result
      end

      def run
        TestResult.new(result)
      end

      def ==(other)
        other.class == self.class && other.result == result
      end
    end

    class ErrorWorkUnit
      attr_reader :exception

      def initialize(exception)
        @exception = exception
      end

      def run
        raise @exception
      end

      def ==(other)
        other.class == self.class && other.exception == exception
      end
    end

    test "exception raised by work unit gives in Agent::Error" do
      options = Options.new({})
      central_command = TestCentralCommand.start options
      work_unit = ErrorWorkUnit.new(exception = TestException.new)
      central_command.write_work work_unit
      central_command.done_with_work

      Agent.new(0, options, stub_everything).execute(StringIO.new, StringIO.new)
      
      assert_equal Agent::Error.new(work_unit, exception), central_command.take_result
    end

    test "Agent::Error can marshal itself even if the contents are not marshallable" do
      o = Object.new
      def o._dump; raise "error"; end

      error = Agent::Error.new o, Exception.new("my error")
      error_through_marshalling = Marshal.load Marshal.dump(error)
      assert_equal Exception, error_through_marshalling.error.class
      assert_equal "my error", error_through_marshalling.error.message
      assert_equal "<< Undumpable >>", error_through_marshalling.work_unit
    end

    test "requests work until it finds some" do
      options = Options.new({})
      central_command = TestCentralCommand.start(options)

      t = Thread.new { Agent.new(0, options, stub_everything).execute(StringIO.new, StringIO.new) }
      Thread.pass
      work_unit = Test::WorkUnit.new(TestFactory.passing_test)
      central_command.write_work work_unit
      central_command.done_with_work
      t.join
      assert_equal TestResult.new(:result), central_command.take_result
    end

    test "finish running if a connection error is received" do
      options = Options.new({})
      central_command = TestCentralCommand.start(options)
      begin
        t = Thread.new { Agent.new(0, options, stub_everything).execute(StringIO.new, StringIO.new) }
        sleep 0.1
      ensure
        central_command.stop
      end
      t.join
    end

    test "number is available to indentify agent" do
      assert_equal 1, Agent.new(1, Options.new({}), nil).number
    end
    
    test "does not fork from rake" do
      assert !defined?($rakefile)
    end
  end
end
