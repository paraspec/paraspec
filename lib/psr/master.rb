module Psr
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
  end
end
