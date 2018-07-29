module Paraspec
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
      @terminal = options[:terminal]
    end

    def run
      unless @terminal
        Process.setpgrp
      end

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
        master = Master.new(:supervisor_pipe => wr)
        master.run
      end
    end

    def run_supervisor
    #p :run_supe
      start_time = Time.now
      #@master = drb_connect(MASTER_DRB_URI, timeout: !@terminal)

      if master_client.request('non-example-exception-count').to_i == 0
        master_client.request('suite-started')

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

        Paraspec.logger.debug("[s] Waiting for workers")
        @worker_pids.each_with_index do |pid, i|
          Paraspec.logger.debug("[s] Waiting for worker #{i+1} at #{pid}")
          wait_for_process(pid)
        end
        status = 0
      else
        status = 1
      end

      master_client.request('dump-summary')
      master_client.request('stop')
      wait_for_process(@master_pid)
      exit status
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
