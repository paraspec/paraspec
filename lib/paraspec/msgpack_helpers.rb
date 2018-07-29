require 'time'

module Paraspec
  module MsgpackHelpers

    def packer
      pk = MessagePack::Packer.new
      pk.register_type(1, Time) do |time|
        time.to_s
      end
      pk
    end

    def unpacker(io)
      uk = MessagePack::Unpacker.new(io)
      uk.register_type(1) do |serialized|
        Time.parse(serialized)
      end
      uk
    end
  end
end
