begin
  Gem::Specification.find_by_name('minitest', '> 5')
  gem 'minitest'
  require 'minitest'

  require File.dirname(__FILE__) + "/minitest/extensions/minitest"
  require File.dirname(__FILE__) + "/minitest/reporters/progress_reporter"
  require File.dirname(__FILE__) + "/minitest/reporters/summary_reporter"
  require File.dirname(__FILE__) + "/minitest/runner"
  require File.dirname(__FILE__) + "/minitest/work_result"
  require File.dirname(__FILE__) + "/minitest/work_unit"
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # MiniTest not found
end
