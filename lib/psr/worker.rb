module Psr
  # A worker process obtains a test to run from the master, runs the
  # test and reports the results, as well as any output, back to the master,
  # then obtains the next test to run and so on.
  # There can be one or more workers participating in a test run.
  # A worker generally loads all of the tests but runs a subset of them.
  class Worker
    def initialize(options={})
      @supervisor_pipe = options[:supervisor_pipe]
      if RSpec.world.example_groups.count > 0
        raise 'Example groups loaded too early/spilled across processes'
      end
      RSpec.configuration.load_spec_files
      # possibly need to signal to supervisor when we are ready to
      # start running tests - there is a race otherwise I think
      puts "#{RSpecFacade.all_example_groups.count} example groups known"
    end

    def run
      DRb.start_service
      @master = DRbObject.new_with_uri(MASTER_DRB_URI)

      runner = WorkerRunner.new(master: @master)

      while spec = @master.get_spec
        runner.run(spec)
      end
    end
  end
end
