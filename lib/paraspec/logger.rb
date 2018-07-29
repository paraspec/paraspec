require 'logger'

module Paraspec
  class LoggerWrapper
    def initialize(logger)
      @logger = logger
    end

    def method_missing(m, *args)
      @logger.send(m, *args)
    end

    %w(ipc).each do |subsystem|
      define_method "log_#{subsystem}=" do |v|
        @subsystems ||= {}
        @subsystems[subsystem] = v
      end

      define_method "log_#{subsystem}?" do
        @subsystems && @subsystems[subsystem] or false
      end

      define_method "debug_#{subsystem}" do |*args|
        if send("log_#{subsystem}?")
          msg = "#{ident || '[?]'} [#{subsystem}] #{args.shift}"
          debug(msg, *args)
        end
      end
    end

    attr_accessor :ident
  end

  class << self
    attr_reader :logger

    def logger=(logger)
      @logger = LoggerWrapper.new(logger)
    end
  end

  self.logger = Logger.new(STDERR)
  self.logger.level = Logger::WARN
end
