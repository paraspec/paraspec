require 'msgpack'
require 'socket'

module Paraspec
  class MsgpackServer
    def initialize(master)
      @master = master
    end

    def run
      @socket = ::TCPServer.new('127.0.0.1', MASTER_APP_PORT)
      while s = @socket.accept
        Thread.new do
          u = MessagePack::Unpacker.new(s)
          u.each do |obj|
            action = obj['action'].gsub('-', '_')
            payload = obj['payload']
            if payload
              payload = IpcHash.new.update(payload)
              args = [payload]
            else
              args = []
            end

            result = @master.send(action, *args)

            packed = MessagePack.pack(result)
            s.write(packed)
          end
        end
      end
    end
  end
end
