module Psr
  # Supervisor is the process that spawns all other processes.
  # Its primary responsibility is to be a "clean slate", specifically
  # the supervisor should not ever have any of the tests loaded in its
  # address space.
  class Supervisor
  end
end
