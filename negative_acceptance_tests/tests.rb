require 'rubygems'
require 'test/unit'
require 'dust'
require 'timeout'

unit_tests do
  [:test].each do |framework|
    test "#{framework}: DeepTest a failing test results in failure" do
      result, output = run_rake framework, :failing
      assert_equal false, result.success?, output
    end

    test "#{framework}: Distributed DeepTest with failover to local" do
      result, output = run_rake framework, :failover_to_local
      assert_equal true, result.success?, output
      assert_match /RSync Failed!!/, output
      assert_match /Failing over to local run/, output
    end

    test "#{framework}: Distributed DeepTest with a host down" do
      result, output = run_rake framework, :just_one_with_host_down
      assert_equal true, result.success?, output
      assert_match /RSync Failed!!/, output
      assert_no_match /Failing over to local run/, output
    end

    test "#{framework}: DeepTest with agents that die" do
      result, output = run_rake framework, :with_agents_dying
      assert_equal false, result.success?, output
      assert_match /DeepTest Agents Are Not Running/, output
      assert_match /DeepTest::IncompleteTestRunError.*100 tests were not run because the DeepTest Agents died/m, output
    end
    
    test "#{framework}: DeepTest processes go away after the test run ends" do
      Timeout.timeout(15) { run_rake framework, :passing }
    end

    test "#{framework}: DeepTest with work taken and not done" do
      result, output = run_rake framework, :with_work_taken_and_not_done 
      assert_equal true, result.success?, output
    end

    test "#{framework}: DeepTest with metrics" do
      FileUtils.rm_f "negative_acceptance_tests/metrics.data"
      result, output = run_rake framework, :with_metrics
      assert_equal true, result.success?, output
      metrics = File.read("negative_acceptance_tests/metrics.data")
      assert_match /Metrics Data/, metrics
      assert_match /Agents Performing Work:/, metrics
      assert_match /Agents Retrieving Work:/, metrics
    end
  end

  def run_rake(framework, task)
    command = "rake --rakefile #{File.dirname(__FILE__)}/tasks.rake deep_#{framework}_#{task} 2>&1"
    command_output = `#{command}`
    output = "[rake deep_#{framework}_#{task}] #{command_output}"
    return $?, output
  end

end
