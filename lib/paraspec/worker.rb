module Paraspec
  # A worker process obtains a test to run from the master, runs the
  # test and reports the results, as well as any output, back to the master,
  # then obtains the next test to run and so on.
  # There can be one or more workers participating in a test run.
  # A worker generally loads all of the tests but runs a subset of them.
  class Worker
    include DrbHelpers

    def initialize(options={})
      @number = options[:number]
      ENV['TEST_ENV_NUMBER'] = @number.to_s
      @supervisor_pipe = options[:supervisor_pipe]
      if RSpec.world.example_groups.count > 0
        raise 'Example groups loaded too early/spilled across processes'
      end
      @terminal = options[:terminal]

      #RSpec.configuration.load_spec_files
      # possibly need to signal to supervisor when we are ready to
      # start running tests - there is a race otherwise I think
      #puts "#{RSpecFacade.all_example_groups.count} example groups known"
    end

    def run
    #puts "worker: #{Process.pid} #{Process.getpgrp}"
      #@master = drb_connect(MASTER_DRB_URI, timeout: !@terminal)

      runner = WorkerRunner.new(master_client: master_client)

      # fill cache when pruning is not set up
      RSpecFacade.all_example_groups
      RSpecFacade.all_examples

      master_example_count = master_client.request('example-count')
      if master_example_count != RSpecFacade.all_examples.count
        # Workers and master should have the same examples defined.
        # If a test suite conditionally defines examples, it needs to
        # ensure that master and worker use the same settings.
        # If worker and master sets of examples differ, when the worker
        # requests an example from master it may receive an example
        # that it can't run.
        # We just check the count for now but may take a digest of
        # defined examples in the future.
        # A mismatch here usually indicates an issue with the test suite
        # being run.
        puts "Worker #{@number} has #{RSpecFacade.all_examples.count} examples, master has #{master_example_count}"
        #byebug
        raise InconsistentTestSuite, "Worker #{@number} has #{RSpecFacade.all_examples.count} examples, master has #{master_example_count}"
      end

      while true
        Paraspec.logger.debug_state("Requesting a spec")
        spec = master_client.request('get-spec')
        Paraspec.logger.debug_state("Got spec #{spec || 'nil'}")
        # HTTP transport returns no spec as an empty hash,
        # msgpack transport returns as nil
        break if spec.nil? || spec.empty?
        spec = IpcHash.new.merge(spec)
        Paraspec.logger.debug_state("Running spec #{spec}")
        runner.run(spec)
        Paraspec.logger.debug_state("Finished running spec #{spec}")
      end
    end

    def ident
      "[w#{@number}]"
    end
  end
end
