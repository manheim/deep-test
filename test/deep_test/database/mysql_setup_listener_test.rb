require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

module DeepTest
  module Database
    unit_tests do
      test "dump_schema includes procedures" do
        listener = MysqlSetupListener.new
        listener.expects(:system).with do |command|
          command =~ / -R /
        end
        listener.expects(:master_database_config).returns({})
        listener.expects(:dump_file_name).returns("")
        listener.expects(:last_process_successful?).returns(true)
        listener.dump_schema
      end
    end
  end
end
