require 'forwardable'
require 'singleton'

module Paraspec
  class RSpecFacade
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :queueable_example_groups, :all_example_groups, :all_examples
    end

    def queueable_example_groups
      @queueable_example_groups ||= begin
        groups = [] + RSpec.world.example_groups
        all_groups = []
        until groups.empty?
          new_groups = []
          groups.each do |group|
            all_groups << group
            if group.metadata[:paraspec] && group.metadata[:paraspec][:split] == false
              # unsplittable group
            else
              new_groups += group.children
            end
          end
          groups = new_groups
        end
        all_groups
      end
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
      @all_examples ||= begin
        filter_manager = RSpec.configuration.filter_manager
        all_example_groups.map do |group|
          filter_manager.prune(group.examples)
        end.flatten
      end
    end
  end
end
