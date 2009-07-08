require File.dirname(__FILE__) + "/../../test_helper"

module DeepTest
  module Distributed
    unit_tests do
      test "load_files broadcasts before_sync" do
        class FakeListener; end
        deployment = RemoteDeployment.new(
          options = Options.new(:listener => FakeListener,
                                :sync_options => {:source => "/tmp"}),
          landing_ship = stub_everything(:establish_beachhead => stub_everything),
          failover_deployment = mock
        )
        FakeListener.any_instance.expects(:before_sync)
        deployment.expects(:load)
        deployment.load_files ["filelist"]

      end

      test "load_files pushes code to remote machines" do
        deployment = RemoteDeployment.new(
          options = Options.new(:sync_options => {:source => "/tmp"}),
          landing_ship = stub_everything(:establish_beachhead => stub_everything),
          failover_deployment = mock
        )

        landing_ship.expects(:push_code).with(options)
        deployment.expects(:load)
        deployment.load_files ["filelist"]
      end

      test "load_files loads files on agent server" do
        beachhead = stub_everything
        deployment = RemoteDeployment.new(
          Options.new(:sync_options => {:source => "/tmp"}),
          landing_ship = stub_everything(:establish_beachhead => beachhead),
          failover_deployment = mock
        )

        beachhead.expects(:load_files).with(["filelist"])
        deployment.expects(:load)
        deployment.load_files ["filelist"]
      end

      test "load_files loads files locally" do
        beachhead = stub_everything
        deployment = RemoteDeployment.new(
          Options.new(:sync_options => {:source => "/tmp"}),
          landing_ship = stub_everything(:establish_beachhead => beachhead),
          failover_deployment = mock
        )

        deployment.expects(:load).with("filelist")
        deployment.load_files ["filelist"]
      end

      test "deploy_agents starts agents on agent server" do
        deployment = RemoteDeployment.new(
          options = Options.new(:sync_options => {:source => "/tmp"}),
          landing_ship = stub_everything,
          failover_deployment = mock
        )

        landing_ship.expects(:establish_beachhead).with(options).
          returns(beachhead = stub_everything)

        deployment.expects(:load)
        deployment.load_files ["filelist"]

        beachhead.expects(:deploy_agents)
        deployment.deploy_agents
      end

      test "exception in deploy_agents causes failover to failover_deployment" do
        deployment = RemoteDeployment.new(
          options = Options.new(:sync_options => {:source => "/tmp"}, :ui => UI::Null),
          landing_ship = stub_everything,
          failover_deployment = mock
        )

        landing_ship.expects(:establish_beachhead).with(options).
          returns(beachhead = mock)

        beachhead.expects(:load_files)
        deployment.expects(:load)
        deployment.load_files ["filelist"]

        beachhead.expects(:deploy_agents).raises("An Error")

        failover_deployment.expects(:deploy_agents)
        deployment.deploy_agents
      end

      test "exception in push_code causes failover to failover_deployment" do
        deployment = RemoteDeployment.new(
          options = Options.new(:sync_options => {:source => "/tmp"}, :ui => UI::Null),
          landing_ship = mock,
          failover_deployment = mock
        )

        landing_ship.expects(:push_code).raises("An Error")

        deployment.expects(:load)
        deployment.load_files ["filelist"]

        failover_deployment.expects(:deploy_agents)
        deployment.deploy_agents
      end

      test "exception in load_files causes failover to failover_deployment" do
        deployment = RemoteDeployment.new(
          options = Options.new(:sync_options => {:source => "/tmp"}, :ui => UI::Null),
          landing_ship = stub_everything,
          failover_deployment = mock
        )

        landing_ship.expects(:establish_beachhead).with(options).
          returns(beachhead = Object.new)

        beachhead.instance_eval do
          def calls() @calls ||= []; end
          def method_missing(sym, *args) calls << sym; end
          def load_files(filelist) raise "An Error"; end
        end

        deployment.expects(:load)
        deployment.load_files ["filelist"]

        failover_deployment.expects(:deploy_agents)
        deployment.deploy_agents

        assert_equal [], beachhead.calls
      end

      test "exception from deploy_agents of failover_deployment is raised" do
        deployment = RemoteDeployment.new(
          options = Options.new(:sync_options => {:source => "/tmp"}, :ui => UI::Null),
          landing_ship = stub_everything,
          failover_deployment = mock
        )

        landing_ship.expects(:establish_beachhead).with(options).
          returns(beachhead = mock)

        beachhead.expects(:load_files).raises("An Error")
        deployment.expects(:load)
        deployment.load_files ["filelist"]

        failover_deployment.expects(:deploy_agents).raises("Failover Error").then.returns(nil)

        begin 
          deployment.deploy_agents
          flunk
        rescue RuntimeError => e
          assert_equal "Failover Error", e.message
        end
      end
    end
  end
end
