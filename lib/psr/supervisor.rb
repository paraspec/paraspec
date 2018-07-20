require 'drb/drb'

module Psr
  # Supervisor is the process that spawns all other processes.
  # Its primary responsibility is to be a "clean slate", specifically
  # the supervisor should not ever have any of the tests loaded in its
  # address space.
  class Supervisor
    include DrbHelpers
    include ProcessHelpers

    def initialize(options={})
      @original_process_title = $0
      $0 = "#{@original_process_title} [supervisor]"
      @concurrency = options[:concurrency] || 1
    end

    def run
      Process.setpgrp
      at_exit { kill_child_processes }

      rd, wr = IO.pipe
      if @master_pid = fork
        # parent
        wr.close
        @master_pipe = rd
        run_supervisor
      else
        # child - master
        $0 = "#{@original_process_title} [master]"
        rd.close
        Master.new(:supervisor_pipe => wr).run
      end
    end

    def run_supervisor
    #p :run_supe
      start_time = Time.now
      @master = drb_connect(MASTER_DRB_URI)

      @master.start
      #DRb.stop_service

      if @master.suite_ok?
        @worker_pipes = []
        @worker_pids = []

        1.upto(@concurrency) do |i|
          rd, wr = IO.pipe
          if worker_pid = fork
            # parent
            wr.close
            @worker_pipes << rd
            @worker_pids << worker_pid
          else
            # child - worker
            $0 = "#{@original_process_title} [worker-#{i}]"
            rd.close
            if RSpec.world.example_groups.count > 0
              raise 'Example groups loaded too early/spilled across processes'
            end
            Worker.new(:number => i, :supervisor_pipe => wr).run
            exit(0)
          end
        end

        Psr.logger.debug("[s] Waiting for workers")
        @worker_pids.each_with_index do |pid, i|
          Psr.logger.debug("[s] Waiting for worker #{i+1} at #{pid}")
          wait_for_process(pid)
        end
      end

      @master.dump_summary

      @master.exit
      wait_for_process(@master_pid)
    end

    def wait_for_process(pid)
      begin
        Process.wait(pid)
      rescue Errno::ECHILD
        # already dead
      end
    end

    def ident
      "[s]"
    end
  end
end
