class SummaryReporter < ::MiniTest::SummaryReporter
  # SummaryReporter without the aggregated results
  def report # :nodoc:
    aggregate = results.group_by { |r| r.failure.class }
    aggregate.default = [] # dumb. group_by should provide this

    self.total_time = ::Minitest.clock_time - start_time
    self.failures   = aggregate[::MiniTest::Assertion].size
    self.errors     = aggregate[::MiniTest::UnexpectedError].size
    self.skips      = aggregate[::MiniTest::Skip].size

    io.sync = old_sync

    io.puts unless options[:verbose] # finish the dots
    io.puts
    io.puts statistics
    io.puts summary
  end
end
