require 'faraday'
require 'json'

module Paraspec
  class HttpClient
    def initialize(options={})
      @terminal = options[:terminal]

      @client = Faraday.new(url: "http://localhost:#{Paraspec::Ipc.master_app_port}") do |client|
        client.adapter :net_http
        if @terminal
          client.options.timeout = 100000
        else
          client.options.timeout = DrbHelpers::WAIT_TIME
        end
      end
    end

    def request(action, payload=nil)
      url = '/' + action
      start_time = Time.now
      begin
        resp = @client.post(url) do |req|
          if payload
            req.headers['content-type'] = 'application/json'
            req.body = payload.to_json
          end
        end
        if resp.status != 200
          raise "Request failed: #{url} (#{resp.status})"
        end
        JSON.parse(resp.body)
      rescue Faraday::ConnectionFailed
        if !@terminal && Time.now - start_time > DrbHelpers::WAIT_TIME
          raise
        else
          sleep 0.1
          retry
        end
      end
    end
  end
end
