require 'rspec/core'

module Psr
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
      @master = output.master
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
      @master.example_passed(spec, notification.example.execution_result)
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
