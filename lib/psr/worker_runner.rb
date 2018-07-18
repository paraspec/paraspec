module Psr
  # An RSpec test runner - in a worker process.
  # This runner collects results and output and forwards them to the
  # master process via DRb.
  class WorkerRunner
    def initialize(options={})
      @master = options[:master]

      # TODO capture stdout & stderr
      class << STDERR
        def master
          @master
        end
      end
      STDERR.send(:instance_variable_set, '@master', @master)
      runner.setup(STDOUT, STDERR)
    end

    def run(spec)
      group = RSpecFacade.all_example_groups.detect do |g|
        g.metadata[:file_path] == spec[:file_path] &&
        g.metadata[:scoped_id] == spec[:scoped_id]
      end
      unless group
      byebug
        raise "No example group for #{spec.inspect}"
      end
      runner.run_specs(group.children).tap do
        #persist_example_statuses
      end
    end

    private def runner
      @runner ||= begin
        options = RSpec::Core::ConfigurationOptions.new(ARGV)
        options.options[:formatters] = [['Psr::WorkerFormatter']]
        RSpec::Core::Runner.new(options)
      end
    end
  end
end
