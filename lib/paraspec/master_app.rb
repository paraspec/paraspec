require 'sinatra'

module Paraspec
  class MasterApp < Sinatra::Base
    post '/non-example-exception-count' do
      master = self.class.settings.master
      payload = master.non_example_exception_count
      content_type 'application/json'
      payload.to_json
    end

    post '/stop' do
      master = self.class.settings.master
      master.stop
      content_type 'application/json'
      {}.to_json
    end

    post '/dump-summary' do
      master = self.class.settings.master
      master.dump_summary
      content_type 'application/json'
      {}.to_json
    end

    post '/next-spec' do
      master = self.class.settings.master
      payload = master.get_spec
      content_type 'application/json'
      (payload || {}).to_json
    end

    post '/example-passed' do
      master = self.class.settings.master
      reqpayloadraw = JSON.parse(request.body.read)
      reqpayload = IpcHash.new.merge(reqpayloadraw)
      result = RSpec::Core::Example::ExecutionResult.new
      reqpayload[:result].each do |k, v|
        result.send("#{k}=", v)
      end
      #p result
      payload = master.example_passed(reqpayload[:spec], result)
      content_type 'application/json'
      payload.to_json
    end

    post '/suite-started' do
      content_type 'application/json'
      {}.to_json
    end
  end
end
