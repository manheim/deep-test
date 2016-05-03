# Subclass of Assertion for unexpected errors.  UnexpectedError
# can not be used as it can include undumpable objects.  This
# class converts all data it needs to plain strings, so that
# it will be dumpable.
class DumpableUnexpectedError < ::Minitest::Assertion # :nodoc:
  attr_accessor :backtrace

  def initialize(unexpected)
    exception_class_name = unexpected.exception.class.name.to_s
    exception_message = unexpected.exception.message.to_s
    super("#{exception_class_name}: #{exception_message}")
    self.backtrace = unexpected.exception.backtrace.map(&:to_s)
  end

  def message
    bt = Minitest.filter_backtrace(backtrace).join "\n    "
    "#{super}\n    #{bt}"
  end

  def result_label
    'Error'
  end
end
