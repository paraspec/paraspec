module Paraspec
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
      #RSpec.configuration.formatter = 'progress'
      if RSpec.world.example_groups.count > 0
        raise 'Example groups loaded too early/spilled across processes'
      end

      rspec_options = RSpec::Core::ConfigurationOptions.new(ARGV)
      @non_example_exception_count = 0
      begin
        # This can fail if for example a nonexistent formatter is referenced
        rspec_options.configure(RSpec.configuration)
      rescue Exception => e
        puts "#{e.class}: #{e}"
        puts e.backtrace.join("\n")
        # TODO and report this situation as a configuration problem
        # and not a test suite problem
        @non_example_exception_count = 1
      end

=begin
      if RSpec.configuration.files_to_run.empty?
        RSpec.configuration.send(:remove_instance_variable, '@files_to_run')
        RSpec.configuration.files_or_directories_to_run = RSpec.configuration.default_path
        RSpec.configuration.files_to_run
        p ['aa1',RSpec.configuration.files_to_run]
        rspec_options.configure(RSpec.configuration)
        RSpec.configuration.load_spec_files
      end
=end

      # It seems that load_spec_files sometimes rescues exceptions outside of
      # examples and sometimes does not, handle it both ways
      if @non_example_exception_count == 0
        begin
          RSpec.configuration.load_spec_files
        rescue Exception => e
          puts "#{e.class}: #{e}"
          puts e.backtrace.join("\n")
          @non_example_exception_count = 1
        end
      end
      if @non_example_exception_count == 0
        @non_example_exception_count = RSpec.world.reporter.non_example_exception_count
      end
      @queue = []
      if @non_example_exception_count == 0
        @queue += RSpecFacade.queueable_example_groups
        puts "#{@queue.length} example groups queued"
      else
        puts "#{@non_example_exception_count} errors outside of examples, aborting"
      end
    end

    attr :non_example_exception_count

    def run
      Thread.new do
        #HttpServer.set(:master, self).run!(port: 6031)
        MsgpackServer.new(self).run
      end
      until @stop
        sleep 1
      end
      Paraspec.logger.debug_state("Exiting")
    end

    def ping
      true
    end

    def stop
      Paraspec.logger.debug_state("Stopping")
      @stop = true
    end

    def stop?
      @stop
    end

    def suite_ok?
      RSpec.configuration.reporter.send(:instance_variable_get,'@non_example_exception_count') == 0
    end

    def example_count
      RSpecFacade.all_examples.count
    end

    def get_spec
      while true
        example_group = @queue.shift
        return nil if example_group.nil?

        if example_group.metadata[:paraspec] && example_group.metadata[:paraspec][:group]
          # unsplittable example group
          # pass to worker as is and have the worker prune examples
          m = example_group.metadata
        else
          # TODO I am still not 100% on what should be filtered and pruned where,
          # but we shouldn't be returning a specification here unless
          # there are tests in it that a worker will run
          pruned_examples = RSpec.configuration.filter_manager.prune(example_group.examples)
          next if pruned_examples.empty?

          m = example_group.metadata
        end

        return {
          file_path: m[:file_path],
          scoped_id: m[:scoped_id],
        }
      end
    end

    def example_passed(payload)
      spec = payload[:spec]
      # ExecutionResult
      result = payload['result']
      do_example_passed(spec, result)
    end

    def notify_example_started(payload)
      example = find_example(payload[:spec])
      reporter.example_started(example)
    end

    def do_example_passed(spec, execution_result)
    #return
      example = find_example(spec)
      # Can write to example here
      example.metadata[:execution_result] = execution_result
      status = execution_result.status
      m = "example_#{status}"
      reporter.send(m, example)
      nil
    end

    def find_example(spec)
      if spec.nil?
        #byebug
        raise ArgumentError, 'Nil spec'
      end
      example = (RSpecFacade.all_example_groups + RSpecFacade.all_examples).detect do |example|
        example.metadata[:file_path] == spec[:file_path] &&
        example.metadata[:scoped_id] == spec[:scoped_id]
      end
      unless example
        puts "Not found: #{spec[:file_path]}[#{spec[:scoped_id]}]"
      #byebug
        raise "Not found: #{spec[:file_path]}[#{spec[:scoped_id]}]"
      end
      example
    end

    def reporter
      @reporter ||= RSpec.configuration.reporter
    end

    def suite_started
      @start_time = Time.now

      notification = RSpec::Core::Notifications::StartNotification.new(
        RSpecFacade.all_examples.count, 0
      )
      RSpec.configuration.formatters.each do |f|
        if f.respond_to?(:start)
          f.start(notification)
        end
      end

      true
    end

    def dump_summary
      reporter.stop

      all_examples = RSpecFacade.all_examples
      notification = RSpec::Core::Notifications::SummaryNotification.new(
        @start_time ? Time.now-@start_time : 0,
        all_examples,
        all_examples.select { |e| e.execution_result.status == :failed },
        all_examples.select { |e| e.execution_result.status == :pending },
        0,
        non_example_exception_count,
      )
      examples_notification = RSpec::Core::Notifications::ExamplesNotification.new(reporter)
      RSpec.configuration.formatters.each do |f|
        if f.respond_to?(:dump_summary)
          f.dump_summary(notification)
        end
        if f.respond_to?(:dump_failures)
          f.dump_failures(examples_notification)
        end
        if f.respond_to?(:dump_pending)
          f.dump_pending(examples_notification)
        end
      end
      nil
    end

    def status
      if RSpecFacade.all_examples.any? { |example| example.execution_result.status == :failed }
        1
      else
        0
      end
    end

    def ident
      "[m]"
    end
  end
end
