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
      Paraspec.logger.ident = '[s]'
      @concurrency = options[:concurrency] || 1
      @terminal = options[:terminal]
      @options = options
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
        if @options[:master_is_1]
          ENV['TEST_ENV_NUMBER'] = '1'
        end
        Paraspec.logger.ident = '[m]'
        rd.close
        master = Master.new(:supervisor_pipe => wr)
        master.run
        exit(0)
      end
    end

    def run_supervisor
      start_time = Time.now

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
            Paraspec.logger.ident = "[w#{i}]"
            rd.close
            if RSpec.world.example_groups.count > 0
              raise 'Example groups loaded too early/spilled across processes'
            end
            Worker.new(:number => i, :supervisor_pipe => wr).run
            exit(0)
          end
        end

        Paraspec.logger.debug_state("Waiting for workers")
        @worker_pids.each_with_index do |pid, i|
          Paraspec.logger.debug_state("Waiting for worker #{i+1} at #{pid}")
          wait_for_process(pid)
        end
        status = 0
      else
        status = 1
      end

      master_client.reconnect!
      puts "dumping summary"
      master_client.request('dump-summary')
      if status == 0
        status = master_client.request('status')
      end
      Paraspec.logger.debug_state("Asking master to stop")
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
