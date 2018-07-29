require 'hashie'

module Paraspec
  #SUPERVISOR_DRB_URI = "druby://localhost:6030"
  MASTER_DRB_URI = "druby://localhost:6031"
  MASTER_APP_PORT = 6031

  class IpcHash < Hash
    include Hashie::Extensions::IndifferentAccess
  end
end
