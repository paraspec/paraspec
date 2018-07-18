module Psr
  module ProcessHelpers
    def kill_child_processes
      # Only kill if we are in supervisor
      return unless Process.pid == Process.getpgrp

      child_pids = `pgrep -g #{$$}`
      if $?.exitstatus != 0
        warn "Failed to run pgrep (#{$?.exitstatus})"
      end
      child_pids = child_pids.strip.split(/\n/).map { |pid| pid.to_i }
      child_pids.delete_if do |pid|
        pid == Process.pid
      end
      child_pids.each do |pid|
        begin
          Process.kill('TERM', pid)
        end
      end
    end
  end
end
