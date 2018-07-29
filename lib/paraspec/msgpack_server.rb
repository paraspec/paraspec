require 'msgpack'
require 'socket'

module Paraspec
  class MsgpackServer
    include MsgpackHelpers

    def initialize(master)
      @master = master
    end

    def run
      @socket = ::TCPServer.new('127.0.0.1', MASTER_APP_PORT)
      while s = @socket.accept
        run_processing_thread(s)
      end
    end

    def run_processing_thread(s)
      Thread.new do
        u = unpacker(s)
        u.each do |obj|
          action = obj['action'].gsub('-', '_')
          payload = obj['payload']
          if payload
            payload = IpcHash.new.merge(payload)
            args = [payload]
          else
            args = []
          end

          Paraspec.logger.debug_ipc("SrvReq:#{obj['id']} #{obj}")
          result = @master.send(action, *args)

          pk = packer(s)
          resp = {result: result}
          Paraspec.logger.debug_ipc("SrvRes:#{obj['id']} #{resp}")
          pk.write(resp)
          pk.flush
          s.flush
        end
      end
    end
  end
end
