class ProgressReporter < ::MiniTest::Reporter
  # Show failures in the progress
  def record(result)
    if options[:verbose]
      io.print(format("%s#%s = %.2f s = ", result.class, result.name, result.time))
    end
    io.print(result.result_code)
    if result.passed?
      io.puts if options[:verbose]
    else
      io.print(result)
    end
  end
end
