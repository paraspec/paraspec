require 'timeout'

module Psr
  module DrbHelpers
    class TimeoutWrapper < BasicObject
      def initialize(target, timeout)
        @target, @timeout = target, timeout
      end

      def method_missing(m, *args)
        ::Timeout.timeout(@timeout) do
          @target.send(m, *args)
        end
      end

      def respond_to?(m, *args)
        super(m, *args) || @target.respond_to?(m, *args)
      end
    end

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
      remote = TimeoutWrapper.new(DRbObject.new_with_uri(uri), 2)
      Psr.logger.debug("#{ident} Waiting for DRb")
      begin
        # Assumes remote has a ping method
        remote.ping
      rescue DRb::DRbConnError, TypeError
        raise if Time.now - start_time > 5
        sleep 0.5
        Psr.logger.debug("#{ident} Retrying DRb ping")
        retry
      rescue Timeout::Error
        raise if Time.now - start_time > 5
        Psr.logger.debug("#{ident} Reconnecting to DRb")
        remote = TimeoutWrapper.new(DRbObject.new_with_uri(uri), 2)
        retry
      end
      remote
    end
  end
end
