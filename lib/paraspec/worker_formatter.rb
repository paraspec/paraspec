require 'rspec/core'

module Paraspec
  class WorkerFormatter
    RSpec::Core::Formatters.register self,
      :start,
      :example_group_started,
      :example_started,
      :example_passed,
      :example_failed,
      :example_pending,
      :message,
      :stop,
      :start_dump,
      :dump_pending,
      :dump_failures,
      :dump_summary,
      :seed,
      :close

    def initialize(output)
      @master_client = output.master_client
    end

    def start(notification)
      #p notification
    end

    def stop(notification)
      #p notification
    end

    def dump_summary(notification)
      #byebug
    end

    def method_missing(m, args)
      #p m
    end

    def example_started(notification)
    end

    def example_passed(notification)
    #byebug
      example_notification(notification)
    end

    def example_notification(notification)
      spec = {
        file_path: notification.example.metadata[:file_path],
        scoped_id: notification.example.metadata[:scoped_id],
      }
      #byebug
      #p :a
      execution_result = notification.example.execution_result
      serialized_er = {}
      %w(started_at finished_at run_time status).each do |field|
        serialized_er[field] = execution_result.send(field)
      end
      @master_client.post_json('/example-passed',
        spec: spec, result: serialized_er)
      #b :b
      #1
    end

    def example_failed(notification)
      example_notification(notification)
    end

    def example_pending(notification)
      example_notification(notification)
    end
  end
end
