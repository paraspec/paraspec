module Paraspec
  class Orchestrator
    def initialize(options={})
      if options[:config_path]
        config = YAML.load(File.read(options[:config_path]))
        @concurrency = config['concurrency']
        @env = config['env']
      end
      if options[:concurrency]
        @concurrency = options[:concurrency]
      else
        @concurrency ||= 1
      end
      @terminal = options[:terminal]
      @options = options
    end

    attr_reader :options

    def run
      Supervisor.new(options).run
    end
  end
end
