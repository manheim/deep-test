module DeepTest
  module MiniTest
    class WorkUnit
      attr_reader :test_suite, :method, :identifier

      def initialize(test_suite, method)
        @test_suite = test_suite
        @method = method
        @identifier = "#{test_suite}##{method}"
      end

      def run
        result = ::Minitest.run_one_method(test_suite, method)
        # Do we really need to make our own WorkResult?
        # Can we pass the actual result
        DeepTest::MiniTest::WorkResult.new(identifier, result)
      end
    end
  end
end
