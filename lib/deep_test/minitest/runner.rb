module DeepTest
  module MiniTest
    class Runner
      def initialize(options)
        @options = options
      end

      def process_work_units(central_command)
        ::MiniTest.load_plugins
        options = ::MiniTest.process_args(ARGV)
        ::MiniTest.reporter = ::MiniTest::CompositeReporter.new
        ::MiniTest.reporter << SummaryReporter.new(options[:io], options)
        ::MiniTest.reporter << ProgressReporter.new(options[:io], options)
        ::MiniTest.init_plugins(options)
        ::MiniTest.reporter.start

        identifiable_work = test_suites.shuffle.each_with_object([]) do |suite, work|
          suite.runnable_methods.shuffle.each do |method|
            work_unit = MiniTest::WorkUnit.new(suite, method)
            work << work_unit.identifier
            central_command.write_work(work_unit)
          end
        end

        MiniTestResultReader.new(central_command).read(identifiable_work) do |_identifiable_work, work_result|
          puts work_result.host unless work_result.result.passed?
          ::MiniTest.reporter.synchronize { ::MiniTest.reporter.record(work_result.result) } # result will come from the output of the test
        end

        ::MiniTest.reporter.report
        ::MiniTest.reporter.passed?
      end

      private

      def test_suites
        ::Minitest::Unit::TestCase.runnables.reject do |suite|
          suite.runnable_methods.empty?
        end
      end
    end
  end
end
