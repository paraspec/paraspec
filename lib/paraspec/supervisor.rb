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

      if options[:config_path]
        config = YAML.load(File.read(options[:config_path]))
        @concurrency = config['concurrency']
        @env = config['env']
      end
      if options[:concurrency]
        @concurrency = options[:concurrency]
      else
        @concurrency ||= 1
      end
      @terminal = options[:terminal]
      @options = options
    end

    def run
      unless @terminal
        Process.setpgrp
      end

      at_exit do
        # It seems that when the tests are run in Travis, killing
        # paraspec vaporizes the standard output... flush the
        # standard output streams here to work around.
        STDERR.flush
        STDOUT.flush
      end

      supervisor_pid = $$
      at_exit do
        # We fork, therefore this handler will be run in master and
        # workers as well but it should only run in supervisor.
        # Guard accordingly
        if $$ == supervisor_pid
          # first kill workers, then master
          ((@worker_pids || []) + [@master_pid]).compact.each do |pid|
            begin
              Process.kill('TERM', pid)
            rescue SystemCallError
            end
          end
          # then kill our process group
          unless @terminal
            kill_child_processes
          end
        end
      end

      Paraspec::Ipc.pick_master_app_port

      # msgpack adds methods to Array, which may change the set of defined
      # examples when a test suite tests proxy objects and checks that, say,
      # each Array method is forwarded. Require msgpack prior to loading
      # test suites in any process.
      require 'msgpack'

      rd, wr = IO.pipe
      if @master_pid = fork
        # parent - supervisor
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

        env_key = if @options[:master_is_1]
          1
        else
          0
        end
        env = @env && @env[env_key]
        if env
          ENV.update(env)
        end

        master = Master.new(:supervisor_pipe => wr)
        master.run
        exit(0)
      end
    end

    def run_supervisor
      start_time = Time.now

      if master_client.request('non_example_exception_count').to_i == 0
        master_client.request('suite_started')

        start_workers
        wait_for_workers

        status = 0
      else
        status = 1
      end

      master_client.reconnect!
      puts "dumping summary"
      master_client.request('dump_summary')
      if status == 0
        status = master_client.request('status')
      end
      Paraspec.logger.debug_state("Asking master to stop")
      master_client.request('stop')
      wait_for_process(@master_pid, 'Master', MasterFailed)
      exit status
    end

    def start_workers
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

          env = @env && @env[i]
          if env
            ENV.update(env)
          end

          if RSpec.world.example_groups.count > 0
            raise 'Example groups loaded too early/spilled across processes'
          end
          Worker.new(:number => i, :supervisor_pipe => wr).run
          exit(0)
        end
      end
    end

    def wait_for_workers
      Paraspec.logger.debug_state("Waiting for workers")
      @worker_pids.each_with_index do |pid, i|
        Paraspec.logger.debug_state("Waiting for worker #{i+1} at #{pid}")
        wait_for_process(pid, "Worker #{i+1}", WorkerFailed)
      end
    end

    def wait_for_process(pid, process_name, exception_class)
      pid, status = Process.wait2(pid)
      if status.exitstatus != 0
        raise exception_class, "#{process_name} exited with status #{status.exitstatus}"
      end
    end

    def ident
      "[s]"
    end
  end
end
