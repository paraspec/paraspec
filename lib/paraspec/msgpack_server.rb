require 'benchmark'
require 'msgpack'
require 'socket'

module Paraspec
  class MsgpackServer
    include MsgpackHelpers

    def initialize(master)
      @master = master
    end

    def run
      @socket = ::TCPServer.new('127.0.0.1', Paraspec::Ipc.master_app_port)
      begin
        while true
          s = @socket.accept_nonblock
          run_processing_thread(s)
        end
      rescue Errno::EAGAIN
        unless @master.stop?
          sleep 0.2
          retry
        end
      end
    end

    def run_processing_thread(s)
      Thread.new do
        u = unpacker(s)
        u.each do |obj|
          result = nil
          time = Benchmark.realtime do
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
            if payload && payload['_noret']
              # Requester does not want a response.
              # We return a hash here because deserializer expects a hash.
              # Always returning `resp` is problematic because it can
              # be non-serializable.
              pk.write({})
            else
              pk.write(resp)
            end
            pk.flush
            s.flush
          end
          Paraspec.logger.debug_perf("SrvReq:#{obj['id']} #{obj['action']}: #{result} #{'%.3f msec' % (time*1000)}")
        end
      end
    end
  end
end
