module DeepTest
  module Test
    class Runner
      unless defined?(NO_FILTERS)
        NO_FILTERS = Object.new.instance_eval do
          def filters; []; end;
          self
        end
      end

      def initialize(options)
        @options = options
      end

      def process_work_units(central_command)
        suite = ::Test::Unit::AutoRunner::COLLECTORS["object_space"].call NO_FILTERS
        supervised_suite = DeepTest::Test::SupervisedTestSuite.new(suite, central_command)
        require 'test/unit/ui/console/testrunner'
        result = ::Test::Unit::UI::Console::TestRunner.run(supervised_suite)
        result.passed?
      end
    end
  end
end
