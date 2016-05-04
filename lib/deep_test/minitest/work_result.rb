module DeepTest
  module MiniTest
    class WorkResult
      include CentralCommand::Result

      attr_reader :identifier, :result, :host

      def initialize(identifier, result)
        @host = Socket.gethostname
        @identifier = identifier
        @result = result
        @result.failures = result.failures.map do |failure|
          DumpableError.new(failure)
        end
      end

      def failed_due_to_deadlock?
        !@result.failures.empty? && DeepTest::DeadlockDetector.due_to_deadlock?(@errors.last)
      end
    end
  end
end
