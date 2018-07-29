require 'sinatra'

module Paraspec
  class HttpServer < Sinatra::Base
    post '/:action' do
      action = params[:action]
      body = request.body.read
      if body.empty?
        args = []
      else
        payload = JSON.parse(body)
        payload = IpcHash.new.merge(payload)
        args = [payload]
      end

      master = self.class.settings.master
      action = action.gsub('-', '_')
      result = master.send(action, *args)

      content_type 'application/json'
      (result || {}).to_json
    end
  end
end
