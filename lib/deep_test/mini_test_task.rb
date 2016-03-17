module DeepTest
  class MiniTestTask < TestTask
    protected

    def runner
      File.expand_path(File.dirname(__FILE__) + "/minitest/run_test_suite.rb")
    end
  end
end
