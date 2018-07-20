require 'logger'

module Psr
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new(Logger::WARN)
end
