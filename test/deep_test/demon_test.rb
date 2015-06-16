require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

module DeepTest
  unit_tests do
    class ProcDemon
      include Demon
      def initialize(block); @block = block; end
      def execute; @block.call; end
    end

    test "forked redirects output back to central command" do
      options = Options.new({})
      operator = TestOperator.listen(options)
      ProcDemon.new(proc do
        puts "hello stdout"
      end).forked("name", options, [])

      after_connecting_to operator do
        assert_equal ProxyIO::Stdout::Output.new("hello stdout"), operator.next_message[0].body
        assert_equal ProxyIO::Stdout::Output.new("\n"), operator.next_message[0].body
      end
    end

    test 're raise an exception' do
      options = Options.new({})
      demon = ProcDemon.new(proc do
        puts "hello stdout"
      end)
      demon.stubs(:execute).raises(Exception.new)

      assert_raise(Errno::ECONNREFUSED) { demon.forked("name", options, []) }
    end

    def after_connecting_to operator, timeout = 5
      start = Time.now
      timedout = false
      until operator.switchboard.any_live_wires? || timedout
        timedout = (Time.now - start) > timeout
      end
      raise "Timed out connection to operator in tests" if timedout
      yield
    end
  end
end

