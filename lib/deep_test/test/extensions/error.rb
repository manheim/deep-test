module Test
  module Unit
    class Error
      BACKTRACE_FILTER = %r{lib/deep_test|telegraph/}
      private_constant :BACKTRACE_FILTER

      def resolve_marshallable_exception
        return unless @exception.is_a?(DeepTest::MarshallableExceptionWrapper)
        @exception = @exception.resolve
      end

      def make_exception_marshallable
        return if @exception.is_a?(DeepTest::MarshallableExceptionWrapper)
        @exception = DeepTest::MarshallableExceptionWrapper.new(@exception)
      end

      def location
        @location = @exception.backtrace.reject { |l| l =~ BACKTRACE_FILTER }
      end
    end
  end
end
