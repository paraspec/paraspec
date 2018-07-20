require 'timeout'

module Psr
  module DrbHelpers
    # Connects to a DRb service and waits for the connection to start working.
    #
    # Interestingly, even when the remote end is up and running
    # talking to it may fail the first time (or few times?)?
    # Supervisor is able to invoke methods on master and subsequently
    # when a worker connects to the master the DRb calls from worker fail.
    # No idea why this is.
    # Work around this by pinging and retrying each DRb connection
    # prior to using it for real work.
    #
    # It appears that any DRb operation can also hang while producing
    # no exceptions or output of any sort.
    private def drb_connect(uri)
      start_time = Time.now
      Psr.logger.debug("#{ident} Connecting to DRb")
      remote = DRbObject.new_with_uri(uri)
      Psr.logger.debug("#{ident} Waiting for DRb")
      wait_for_drb do
        begin
          Timeout.timeout(1) do
            # Assumes remote has a ping method
            remote.ping
          end
        rescue DRb::DRbConnError, TypeError
          raise if Time.now - start_time > 5
          sleep 0.5
          Psr.logger.debug("#{ident} Retrying DRb ping")
          retry
        rescue Timeout::Error
          raise if Time.now - start_time > 5
          Psr.logger.debug("#{ident} Reconnecting to DRb")
          remote = DRbObject.new_with_uri(uri)
          retry
        end
      end
      remote
    end
  end
end
