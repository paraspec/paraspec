require 'forwardable'
require 'singleton'

module Psr
  class RSpecFacade
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :all_example_groups, :all_examples
    end

    def all_example_groups
    #byebug
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
      @all_examples ||= all_example_groups.map { |g| g.examples }.flatten
    end
  end
end
