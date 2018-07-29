require 'paraspec/rspec_patches'
require 'paraspec/version'
require 'paraspec/logger'
require 'paraspec/ipc'
require 'paraspec/drb_helpers'
require 'paraspec/process_helpers'
require 'paraspec/supervisor'
require 'paraspec/master'
require 'paraspec/worker'
require 'paraspec/master_runner'
require 'paraspec/worker_runner'
require 'paraspec/worker_formatter'
require 'paraspec/rspec_facade'

module Paraspec
  autoload :HttpClient, 'paraspec/http_client'
  autoload :HttpServer, 'paraspec/http_server'
end
