module Psr
  # A worker process obtains a test to run from the master, runs the
  # test and reports the results, as well as any output, back to the master,
  # then obtains the next test to run and so on.
  # There can be one or more workers participating in a test run.
  # A worker generally loads all of the tests but runs a subset of them.
  class Worker
    def initialize(options={})
      @supervisor_pipe = options[:supervisor_pipe]
    end

    def run
      @master = DRbObject.new_with_uri(MASTER_DRB_URI)
    end
  end
end
