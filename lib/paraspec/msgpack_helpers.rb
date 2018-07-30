require 'time'

module Paraspec
  module MsgpackHelpers

    def packer(io)
      pk = MessagePack::Packer.new(io)
      pk.register_type(1, Time) do |time|
        time.to_s
      end
      pk.register_type(2, RSpec::Core::Example::ExecutionResult) do |er|
        serialized = {}
        %w(started_at finished_at run_time status).each do |field|
          serialized[field] = er.send(field)
        end
        %w(exception pending_exception).each do |field|
          serialized[field] = Marshal.dump(er.send(field))
        end
        Marshal.dump(serialized)
      end
      pk
    end

    def unpacker(io)
      uk = MessagePack::Unpacker.new(io)
      uk.register_type(1) do |serialized|
        Time.parse(serialized)
      end
      uk.register_type(2) do |serialized|
        serialized = Marshal.load(serialized)
        er = RSpec::Core::Example::ExecutionResult.new
        serialized.each do |k, v|
          if k == 'status'
            v = v.to_sym
          end
          if %w(exception pending_exception).include?(k)
            v = Marshal.load(v)
          end
          er.send("#{k}=", v)
        end
        er
      end
      uk
    end
  end
end
