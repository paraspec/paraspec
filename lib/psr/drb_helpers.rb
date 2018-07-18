module Psr
  module DrbHelpers
    # Waits for a DRb service to start working.
    #
    # Interestingly, even when the remote end is up and running
    # talking to it may fail the first time (or few times?)?
    # Supervisor is able to invoke methods on master and subsequently
    # when a worker connects to the master the DRb calls from worker fail.
    # No idea why this is.
    # Work around this by pinging and retrying each DRb connection
    # prior to using it for real work.
    private def wait_for_drb
      start_time = Time.now
      begin
        yield
      rescue DRb::DRbConnError, TypeError
        if Time.now - start_time < 50
          sleep 0.5
          retry
        else
          raise
        end
      end
    end

    private def drb_connect(uri)
      remote = DRbObject.new_with_uri(uri)
      wait_for_drb do
        # Assumes remote has a ping method
        remote.ping
      end
      remote
    end
  end
end
