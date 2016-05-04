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
        DeepTest::MiniTest::WorkResult.new(identifier, result)
      end
    end
  end
end
