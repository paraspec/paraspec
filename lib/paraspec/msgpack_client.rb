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
      req = {action: action, payload: payload}
      p req
      msg = packer.pack(req)
      p msg
      @socket.write(msg)
      response = unpacker(@socket).unpack
      if Hash === response
        response = IpcHash.new.merge(response)
      end
      p [:rrr,response]
      response
    end
  end
end
