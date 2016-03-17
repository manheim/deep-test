module DeepTest
  module MiniTest
    class WorkResult
      include CentralCommand::Result

      attr_reader :identifier, :errors, :result

      def initialize(identifier, result)
        @result = result
        @identifier = identifier
        @errors = result.failures
      end

      def failed_due_to_deadlock?
        !@errors.empty? && DeepTest::DeadlockDetector.due_to_deadlock?(@errors.last)
      end
    end
  end
end
