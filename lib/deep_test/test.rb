begin
  gem 'test-unit'
  require 'test/unit'
  require "test/unit/testresult"
  require "test/unit/error"
  require 'test/unit/failure'
  require 'test/unit/autorunner'

  require File.dirname(__FILE__) + "/test/extensions/error"
  require File.dirname(__FILE__) + "/test/runner"
  require File.dirname(__FILE__) + "/test/supervised_test_suite"
  require File.dirname(__FILE__) + "/test/work_unit"
  require File.dirname(__FILE__) + "/test/work_result"
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # test-unit not found
end
