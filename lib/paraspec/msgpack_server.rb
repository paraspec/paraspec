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

            puts "SrvReq:#{obj['id']} #{obj}"
            result = @master.send(action, *args)

            pk = packer(s)
            resp = {result: result}
            puts "SrvRes:#{obj['id']} #{resp}"
            pk.write(resp)
            pk.flush
            s.flush

            if @master.stop?
              exit 0
            end
          end
        end
      end
    end
  end
end
