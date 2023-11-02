module Paraspec
  # An RSpec test runner - in a worker process.
  # This runner collects results and output and forwards them to the
  # master process via DRb.
  class WorkerRunner
    def initialize(options={})
      @master_client = options[:master_client]

      # TODO capture stdout & stderr
      class << STDERR
        def master_client
          @master_client
        end
      end
      STDERR.send(:instance_variable_set, '@master_client', @master_client)
      runner.setup(STDOUT, STDERR)
    end

    def run(spec)
      if RSpecFacade.all_example_groups.count == 0
        raise InternalError, "No example groups loaded"
      end
      group = RSpecFacade.all_example_groups.detect do |g|
        g.metadata[:rerun_file_path] == spec[:file_path] &&
        g.metadata[:scoped_id] == spec[:scoped_id]
      end
      unless group
        puts "No example group for #{spec.inspect}, #{RSpecFacade.all_example_groups.count} total groups"
      #byebug
        raise InternalError, "No example group for #{spec.inspect}"
      end
      if group.metadata[:paraspec] && group.metadata[:paraspec][:group]
        # unsplittable group
        # get all examples in child groups
        examples = []
        group_queue = [group]
        until group_queue.empty?
          next_group_queue = []
          group_queue.each do |group|
            next_group_queue += group.children
            examples += group.examples
          end
          group_queue = next_group_queue
        end
      else
        # leaf group
        examples = group.examples
        #Paraspec.logger.debug_state("Spec #{spec}: #{examples.length} examples")
        return if examples.empty?
        ids = examples.map { |e| e.metadata[:scoped_id] }
        RSpec.configuration.send(:instance_variable_set, '@filter_manager', RSpec::Core::FilterManager.new)
        RSpec.configuration.filter_manager.add_ids(spec[:file_path], ids)
        RSpec.world.filter_examples
        examples = RSpec.configuration.filter_manager.prune(examples)
      end
      return if examples.empty?
      # It is important to run the entire world here because if
      # a particular example group is run, before/after :all hooks
      # aren't always run.
      # And "the entire world" means our complete list of example groups,
      # not RSpec.world.ordered_example_groups which are top level only!
      RSpecFacade.all_example_groups.each do |group|
        group.reset_memoized
      end
      # Hack to not run examples from each group each time I want to run
      # a single example. It seems that rspec performs filtering by file
      # at one time and by expressions/scoped id at a different time,
      # because simply requesting filtering by scoped id makes rspec
      # include examples from all other files (it also mutates the filters
      # when querying them for example groups... ugh)
      run_example_groups = RSpec.world.ordered_example_groups.select do |c_group|
        c_group.metadata[:rerun_file_path] == spec[:file_path]
      end
      runner.run_specs(run_example_groups)
    end

    private def runner
      @runner ||= begin
        options = RSpec::Core::ConfigurationOptions.new(ARGV)
        options.options[:formatters] = [['Paraspec::WorkerFormatter']]
        RSpec::Core::Runner.new(options)
      end
    end
  end
end
