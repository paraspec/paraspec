require 'hashie'
require 'socket'

module Paraspec
  class IpcHash < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  module Ipc
    class << self
      def pick_master_app_port
        port = 10000 + rand(40000)
        begin
          server = TCPServer.new('127.0.0.1', port)
          server.close
          return @master_app_port = port
        rescue Errno::EADDRINUSE
          port = 10000 + rand(40000)
          retry
        end
      end

      attr_reader :master_app_port
    end
  end
end
