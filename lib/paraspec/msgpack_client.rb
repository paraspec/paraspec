require 'msgpack'
require 'socket'

module Paraspec
  class MsgpackClient
    include MsgpackHelpers

    def initialize(options={})
      @terminal = options[:terminal]

      start_time = Time.now
      begin
        @socket = TCPSocket.new('127.0.0.1', MASTER_APP_PORT)
      rescue Errno::ECONNREFUSED
        if !@terminal && Time.now - start_time > DrbHelpers::WAIT_TIME
          raise
        else
          sleep 0.1
          retry
        end
      end
    end

    def request(action, payload=nil)
      req = {action: action, payload: payload, id: request_id}
      puts "CliReq:#{req[:id]} #{req}"
      p req
      pk = packer(@socket)
      pk.write(req)
      pk.flush
      puts 'Waiting for response'
      response = unpacker(@socket).unpack
      puts "CliRes:#{req[:id]} #{response}"
      response = IpcHash.new.merge(response)
      p [:rrr,response]
      response[:result]
    end

    def request_id
      @request_num ||= 0
      "#{$$}:#{@request_num += 1}"
    end
  end
end
