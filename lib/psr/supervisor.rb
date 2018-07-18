require 'drb/drb'

module Psr
  # Supervisor is the process that spawns all other processes.
  # Its primary responsibility is to be a "clean slate", specifically
  # the supervisor should not ever have any of the tests loaded in its
  # address space.
  class Supervisor
    def run
      Process.setpgrp

      rd, wr = IO.pipe
      if @master_pid = fork
        # parent
        wr.close
        @master_pipe = rd
        run_supervisor
      else
        # child - master
        rd.close
        Master.new(:supervisor_pipe => wr).run
      end
    end

    def run_supervisor
      start_time = Time.now
      @master = DRbObject.new_with_uri(MASTER_DRB_URI)
      begin
        @master.ping
      rescue DRb::DRbConnError
        if Time.now - start_time < 5
          sleep 0.5
          retry
        else
          raise
        end
      end

      if @master.suite_ok?
      end

      @master.exit
      Process.wait(@master_pid)
    end
  end
end
