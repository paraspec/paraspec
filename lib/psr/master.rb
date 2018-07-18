module Psr
  # The master process has three responsibilities:
  # 1. Load all tests and abort the run if there are errors outside of
  #    examples.
  # 2. Maintain the queue of tests to feed the workers. The master
  #    process also synchronizes access to this queue.
  # 3. Aggregate test reports from the workers and present them to
  #    the outside world in a coherent fashion. The latter means
  #    that numbers presented are for the entire suite, not for parts
  #    of it as executed by any single worker, and that output from a
  #    single test execution is not broken up by output from other test
  #    executions.
  class Master
    def initialize(options={})
      @supervisor_pipe = options[:supervisor_pipe]
      RSpec.configuration.load_spec_files
      @queue = [] + all_example_groups
    end

    def run
      DRb.start_service(MASTER_DRB_URI, self)
      until @stop
        sleep 1
      end
    end

    def ping
      true
    end

    def exit
      @stop = true
    end

    def suite_ok?
      RSpec.configuration.reporter.send(:instance_variable_get,'@non_example_exception_count') == 0
    end

    def all_example_groups
      @all_example_groups ||= begin
        groups = [] + RSpec.world.example_groups
        all_groups = []
        until groups.empty?
          new_groups = []
          groups.each do |group|
            all_groups << group
            new_groups += group.children
          end
          groups = new_groups
        end
        all_groups
      end
    end

    def all_examples
      @all_examples ||= all_example_groups.map { |g| g.examples }.flatten
    end

    def get_spec
      example_group = @queue.shift
      return nil if example_group.nil?

      m = example_group.metadata
      {
        file_path: m[:file_path],
        scoped_id: m[:scoped_id],
      }
    end

    def example_passed(spec, execution_result)
    #return
      example = find_example(spec)
      # Can write to example here
      example.metadata[:execution_result] = execution_result
      status = execution_result.status
      m = "example_#{status}"
      #RSpec.configuration.reporter.report(1) do |reporter|
        reporter.send(m, example)
      #end
      #byebug
      #p args
    end

    def find_example(spec)
      example = all_examples.detect do |example|
        example.metadata[:file_path] == spec[:file_path] &&
        example.metadata[:scoped_id] == spec[:scoped_id]
      end
      unless example
      byebug
        raise "Not found: #{spec[:file_path]}[#{spec[:scoped_id]}]"
      end
      example
    end

    def reporter
      @reporter ||= RSpec.configuration.reporter
    end
  end
end
