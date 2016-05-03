module DeepTest
  module MiniTest
    class WorkResult
      include CentralCommand::Result

      attr_reader :identifier, :errors, :result, :host

      def initialize(identifier, result)
        @host = Socket.gethostname
        @identifier = identifier
        @errors = result.failures
        @errors = result.failures.map do |failure|
          if failure.is_a?(::Minitest::UnexpectedError)
            DumpableUnexpectedError.new(failure)
          else
            failure
          end
        end
        @result = result
        @result.failures = @errors
      end

      def failed_due_to_deadlock?
        !@errors.empty? && DeepTest::DeadlockDetector.due_to_deadlock?(@errors.last)
      end
    end
  end
end
