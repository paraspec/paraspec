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
    def initialize(options)
      @supervisor_pipe = options[:supervisor_pipe]
      RSpec.configuration.load_spec_files
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
  end
end
