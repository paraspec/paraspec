module Paraspec
  # Base class for all Paraspec errors
  class Error < StandardError; end

  # Different set of examples between master and a worker
  class InconsistentTestSuite < Error; end

  # A worker process exited with non-zero status
  class WorkerFailed < Error; end

  # Master process exited with non-zero status
  class MasterFailed < Error; end

  # There were errors while loading the test suite
  class TestLoadError < Error; end
end
