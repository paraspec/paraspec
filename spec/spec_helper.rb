#$: << 'lib'

require 'ostruct'
require 'tempfile'
require 'childprocess'
require 'byebug'

module Macros
end

module Helpers
  class ProcessWrapper
    def initialize(process)
      @process = process
    end

    attr_reader :process

    def pid
      process.pid
    end

    def wait
      process.wait
      process.io.stdout.rewind
      process.io.stderr.rewind
      rv = OpenStruct.new(
        output: process.io.stdout.read,
        errput: process.io.stderr.read,
        exit_code: process.exit_code,
      )
      process.io.stdout.close
      process.io.stderr.close
      rv
    end
  end

  def start_paraspec_in_fixture(fixture, *cmd)
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'bin', 'paraspec'))
    cmd = [bin_path] + cmd

    process = nil
    Dir.chdir(File.join('fixtures', fixture)) do
      process = ChildProcess.new(*cmd)
      process.io.stdout = Tempfile.new('pss')
      process.io.stderr = Tempfile.new('pss')
      #process.io.inherit!
      process.start
    end

    ProcessWrapper.new(process)
  end

  def run_paraspec_in_fixture(fixture, *cmd)
    start_paraspec_in_fixture(fixture, *cmd).wait
  end
end

RSpec.configure do |config|
  config.extend Macros
  config.include Helpers
  config.expect_with(:rspec) do |c|
    c.syntax = :should
  end
end
