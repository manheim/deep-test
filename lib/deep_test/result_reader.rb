module DeepTest
  class ResultReader
    DEFAULT_COLUMNS = 130

    def initialize(central_command)
      @central_command = central_command
    end

    def read(original_work_units_by_id)
      @output_count = 0
      work_units_by_id = original_work_units_by_id.dup
      errors = 0

      begin
        until errors == work_units_by_id.size
          Thread.pass
          result = @central_command.take_result
          next if result.nil?

          if Agent::Error === result
            puts result
            @output_count = 0
            errors += 1
          else
            if result.respond_to?(:output) && (output = result.output)
              print(output.empty? ? "." : output)
              @output_count += 1
              if window_size - @output_count <= 0
                @output_count = 0
                print("\n")
              end
            end

            work_unit = work_units_by_id.delete(result.identifier)
            yield [work_unit, result]
          end
        end
      rescue CentralCommand::NoAgentsRunningError
        FailureMessage.show "DeepTest Agents Are Not Running", <<-end_msg
          DeepTest's test running agents have not contacted the
          server to indicate they are still running.
          Shutting down the test run on the assumption that they have died.
        end_msg
      end

      work_units_by_id
    end

    private

    def window_size
      # do not cache this value incase the screen is resized
      width = window_size_from_io.to_i
      width = window_size_from_env.to_i if width == 0
      width = DEFAULT_COLUMNS if width == 0
      width
    end

    def window_size_from_io
      $stdout.winsize[1] if $stout.respond_to?(:winsize) || IO.console.winsize[1] if IO.console
    end

    def window_size_from_env
      ENV['COLUMNS'] || ENV["TERM_WIDTH"]
    end
  end
end
