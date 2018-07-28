require 'rspec/core'

class RSpec::Core::Configuration
  # https://github.com/rspec/rspec-core/commit/e7bb36342b8a3aca2512a0335ea9836780a60605
  # Will probably add a flag to configuration to load default_path
  # regardless of $0
  def command
    'rspec'
  end
end

class RSpec::Core::World
  # https://github.com/rspec/rspec-core/pull/2552
  def filter_examples
    @filtered_examples = Hash.new do |hash, group|
      hash[group] = filter_manager.prune(group.examples)
    end
  end
end

class RSpec::Core::Reporter
  attr_reader :non_example_exception_count
end
