module DeepTest
  class << self
    def logger
      @logger ||= DeepTest::Logger.new($stdout)
    end

    def logger=(logger)
      @logger = logger
    end
  end  

  class IncompleteTestRunError < StandardError
    def initialize(count)
      super "#{count} tests were not run because the DeepTest Agents died"
    end

    def backtrace
      []
    end
  end
end

require "logger"
require "timeout"
require "thread"
require "socket"
require "webrick"
require "timeout"
require "base64"
require 'io/console'

require File.dirname(__FILE__) + "/telegraph"
require File.dirname(__FILE__) + "/deep_test/lib_root"
require File.dirname(__FILE__) + "/deep_test/extensions/object_extension"

require File.dirname(__FILE__) + "/deep_test/demon"
require File.dirname(__FILE__) + "/deep_test/deadlock_detector"
require File.dirname(__FILE__) + "/deep_test/local_deployment"
require File.dirname(__FILE__) + "/deep_test/logger"

require File.dirname(__FILE__) + "/deep_test/marshallable_exception_wrapper"
require File.dirname(__FILE__) + "/deep_test/null_listener"
require File.dirname(__FILE__) + "/deep_test/listener_list"
require File.dirname(__FILE__) + "/deep_test/cpu_info"
require File.dirname(__FILE__) + "/deep_test/failure_message"
require File.dirname(__FILE__) + "/deep_test/options"
require File.dirname(__FILE__) + "/deep_test/main"
require File.dirname(__FILE__) + "/deep_test/result_reader"
require File.dirname(__FILE__) + "/deep_test/rspec_detector"
require File.dirname(__FILE__) + "/deep_test/central_command"
require File.dirname(__FILE__) + "/deep_test/proxy_io"
require File.dirname(__FILE__) + "/deep_test/test_task"
require File.dirname(__FILE__) + "/deep_test/agent"
require File.dirname(__FILE__) + "/deep_test/warlock"

require File.dirname(__FILE__) + "/deep_test/database/setup_listener"
require File.dirname(__FILE__) + "/deep_test/database/mysql_setup_listener"

require File.dirname(__FILE__) + "/deep_test/distributed/shell_environment"
require File.dirname(__FILE__) + "/deep_test/distributed/landing_ship"
require File.dirname(__FILE__) + "/deep_test/distributed/dispatch_controller"
require File.dirname(__FILE__) + "/deep_test/distributed/ssh_client_connection_info"
require File.dirname(__FILE__) + "/deep_test/distributed/filename_resolver"
require File.dirname(__FILE__) + "/deep_test/distributed/landing_fleet"
require File.dirname(__FILE__) + "/deep_test/distributed/remote_deployment"
require File.dirname(__FILE__) + "/deep_test/distributed/beachhead"
require File.dirname(__FILE__) + "/deep_test/distributed/rsync"

require File.dirname(__FILE__) + "/deep_test/metrics/data"
require File.dirname(__FILE__) + "/deep_test/metrics/measurement"

DeepTest::RSpecDetector.if_rspec_available do
  require File.dirname(__FILE__) + "/deep_test/spec"
end
require File.dirname(__FILE__) + "/deep_test/test"

require File.dirname(__FILE__) + "/deep_test/ui/console"
require File.dirname(__FILE__) + "/deep_test/ui/null"

