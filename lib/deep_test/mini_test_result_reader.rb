module DeepTest
  class MiniTestResultReader < ResultReader
    def read(original_work_units_by_id)
      @output_count = 0
      work_units_by_id = original_work_units_by_id.dup
      errors = 0

      begin
        until errors == work_units_by_id.size
          Thread.pass
          result = @central_command.take_result
          next if result.nil?

          if result.is_a?(Agent::Error)
            puts result
            @output_count = 0
            errors += 1
          else
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
  end
end
