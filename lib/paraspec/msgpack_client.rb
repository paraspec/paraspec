require 'msgpack'
require 'socket'

module Paraspec
  class MsgpackClient
    include MsgpackHelpers

    def initialize(options={})
      @terminal = options[:terminal]

      connect
    end

    def request(action, payload=nil)
      req = {action: action, payload: payload, id: request_id}
      Paraspec.logger.debug_ipc("CliReq:#{req[:id]} #{req}")
      pk = packer(@socket)
      pk.write(req)
      pk.flush
      response = unpacker(@socket).unpack
      Paraspec.logger.debug_ipc("CliRes:#{req[:id]} #{response}")
      response = IpcHash.new.merge(response)
      response[:result]
    end

    def request_id
      @request_num ||= 0
      "#{$$}:#{@request_num += 1}"
    end

    # The socket doesn't stay operational after a fork even if the child
    # process never uses it. Parent should reconnect after forking
    # any children
    def reconnect!
      @socket.close
      connect
    end

    private def connect
      start_time = Time.now
      begin
        @socket = TCPSocket.new('127.0.0.1', Paraspec::Ipc.master_app_port)
      rescue Errno::ECONNREFUSED
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
