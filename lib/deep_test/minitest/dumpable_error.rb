# Exceptions are not guaranteed to be dumpable. The idea for this came from
# [`minitest-paralle_fork`](https://github.com/jeremyevans/minitest-parallel_fork).
class DumpableError < ::Minitest::Assertion # :nodoc:
  attr_accessor :backtrace
  attr_reader :class, :result_code, :result_label

  def initialize(exception)
    # Lie about what class we actually are so that the `Minitest::Reporter`
    # will report the actual error instead of the wrapped error. This is also
    # needed to make the summary report work
    @class = exception.class
    @result_code = exception.result_code
    @result_label = exception.result_label
    super exception.message
    self.backtrace = exception.backtrace
  end

  def message
    bt = Minitest.filter_backtrace(backtrace).join "\n    "
    "#{super}\n    #{bt}"
  end
end
