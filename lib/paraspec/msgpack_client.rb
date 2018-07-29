require 'msgpack'
require 'socket'

module Paraspec
  class MsgpackClient
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
      req = {action: action, payload: payload}
      msg = MessagePack.pack(req)
      p req
      p msg
      @socket.write(msg)
      response = MessagePack::Unpacker.new(@socket).unpack
    end
  end
end
