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
      rspec_options.configure(RSpec.configuration)
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

      RSpec.configuration.load_spec_files
      @non_example_exception_count = RSpec.world.reporter.non_example_exception_count
      @queue = []
      if @non_example_exception_count == 0
        @queue += RSpecFacade.all_example_groups
        puts "#{@queue.length} example groups queued"
      else
        puts "#{@non_example_exception_count} errors outside of examples, aborting"
      end
    end

    attr :non_example_exception_count

    def run
#    puts "master: #{Process.pid} #{Process.getpgrp}"
      #p :start
      Thread.new do
        HttpServer.set(:master, self).run!(port: 6031)
      end
      until @stop
        sleep 1
      end
    end

    def ping
      true
    end

    def stop
      @stop = true
    end

    def suite_ok?
      RSpec.configuration.reporter.send(:instance_variable_get,'@non_example_exception_count') == 0
    end

    def get_spec
    #p :getting_spec
      example_group = @queue.shift
      return nil if example_group.nil?

      m = example_group.metadata
      {
        file_path: m[:file_path],
        scoped_id: m[:scoped_id],
      }
    end

    def example_passed(payload)
      spec = payload[:spec]
      result = RSpec::Core::Example::ExecutionResult.new
      payload[:result].each do |k, v|
        result.send("#{k}=", v)
      end
      do_example_passed(spec, result)
    end

    def do_example_passed(spec, execution_result)
    #return
      example = find_example(spec)
      # Can write to example here
      example.metadata[:execution_result] = execution_result
      status = execution_result.status
      m = "example_#{status}"
      #RSpec.configuration.reporter.report(1) do |reporter|
      #p RSpec.configuration.formatters
      #ii
      #p ['send', example.metadata[:scoped_id]]
        reporter.send(m, example)
      notification = RSpec::Core::Notifications::ExampleNotification.for(example)
      RSpec.configuration.formatters.each do |f|
        if f.respond_to?(m)
          #f.send(m, notification)
        end
      end
      #end
      #byebug
      #p args
      nil
    end

    def find_example(spec)
      if spec.nil?
        byebug
        raise ArgumentError, 'Nil spec'
      end
      example = RSpecFacade.all_examples.detect do |example|
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

    def suite_started
      @start_time = Time.now
      true
    end

    def dump_summary
      all_examples = RSpecFacade.all_examples
      notification = RSpec::Core::Notifications::SummaryNotification.new(
        @start_time ? Time.now-@start_time : 0,
        all_examples,
        all_examples.select { |e| e.execution_result.status == :failed },
        all_examples.select { |e| e.execution_result.status == :pending },
        0,
        non_example_exception_count,
      )
      #p notification
      examples_notification = RSpec::Core::Notifications::ExamplesNotification.new(reporter)
      RSpec.configuration.formatters.each do |f|
        if f.respond_to?(:dump_summary)
          f.dump_summary(notification)
          f.dump_failures(examples_notification)
          f.dump_pending(examples_notification)
        end
      end
      #p :fini, $$
      nil
    end

    def ident
      "[m]"
    end
  end
end
