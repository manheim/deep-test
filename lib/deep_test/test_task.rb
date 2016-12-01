module DeepTest
  class TestTask
    require 'rake'
    include Rake::DSL
    attr_accessor :libs, :requires

    def initialize(name = :deep_test)
      @requires = []
      @name = name
      @libs = ["lib"]
      @options = Options.new({})
      self.pattern = "test/**/*_test.rb"
      yield self if block_given?
      define
    end

    def define
      desc "Run '#{@name}' suite using DeepTest"
      task @name do
        lib_options = @libs.any? ? "-I" + @libs.join(File::PATH_SEPARATOR) : ""
        require_options = requires.map {|f| "-r#{f}"}.join(" ")
        ruby "#{lib_options} #{require_options} #{runner} '#{@options.to_command_line}'"
      end
    end

    Options::VALID_OPTIONS.each do |option|
      class_eval <<-end_src, __FILE__, __LINE__
        def #{option.name}
          @options.#{option.name}
        end

        def #{option.name}=(value)
          @options.#{option.name} = value
        end
      end_src
    end

    def pattern=(pattern)
      @options.pattern = Dir.pwd + "/" + pattern
    end

    protected

    def runner
      File.expand_path(File.dirname(__FILE__) + "/test/run_test_suite.rb")
    end
  end
end
