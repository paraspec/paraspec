require 'timeout'

module Paraspec
  module DrbHelpers
    WAIT_TIME = 500

=begin
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
    private def drb_connect(uri, timeout: true)
      start_time = Time.now
      Paraspec.logger.debug("#{ident} Connecting to DRb")
      remote = TimeoutWrapper.new(DRbObject.new_with_uri(uri), 2)
      Paraspec.logger.debug("#{ident} Waiting for DRb")
      begin
        # Assumes remote has a ping method
        remote.ping
      rescue DRb::DRbConnError, TypeError
        raise if timeout && Time.now - start_time > WAIT_TIME
        sleep 0.5
        Paraspec.logger.debug("#{ident} Retrying DRb ping")
        retry
      rescue Timeout::Error
        raise if timeout && Time.now - start_time > WAIT_TIME
        Paraspec.logger.debug("#{ident} Reconnecting to DRb")
        remote = TimeoutWrapper.new(DRbObject.new_with_uri(uri), 2)
        retry
      end
      remote
    end
=end

    def master_client
      @master_client ||= begin
        Faraday.new(url: "http://localhost:#{Paraspec::MASTER_APP_PORT}") do |client|
          client.adapter :net_http
          if @terminal
            client.options.timeout = 100000
          else
            client.options.timeout = DrbHelpers::WAIT_TIME
          end
          class << client
            def post_json(url, body=nil)
              method_json(:post, url, body)
            end

            def method_json(meth, url, body=nil)
              start_time = Time.now
              begin
                resp = send(meth, url) do |req|
                  if body
                    req.headers['content-type'] = 'application/json'
                    req.body = body.to_json
                  end
                end
                if resp.status != 200
                  raise "Request failed: #{url} (#{resp.status})"
                end
                JSON.parse(resp.body)
              rescue Faraday::ConnectionFailed
                if Time.now - start_time > DrbHelpers::WAIT_TIME
                  raise
                else
                  sleep 0.1
                  retry
                end
              end
            end
          end
        end
      end
    end

    def symbolize_keys(hash)
      out = {}
      hash.each do |k, v|
        out[k.to_sym] = v
      end
      out
    end
  end
end
