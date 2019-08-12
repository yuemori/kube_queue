require 'kube_queue/worker/dsl'
require 'kube_queue/job_specification'

module KubeQueue
  module Worker
    def self.included(base)
      base.extend(ClassMethods)

      KubeQueue.register_worker(base.name, base)
    end

    module ClassMethods
      include DSL

      def enqueue(body = nil)
        KubeQueue.executor.enqueue(new, body)
      end
      alias_method :perform_async, :enqueue

      def enqueue_at(body = nil)
        KubeQueue.executor.enqueue(new, body)
      end

      def read_template
        File.read(@template || File.expand_path('../../../template/job.yaml', __FILE__))
      end
    end

    def template
      self.class.read_template
    end

    def job_spec
      self.class.job_spec
    end

    attr_accessor :job_id, :arguments

    def initialize(*arguments)
      # Compatibility for ActiveJob interface
      super

      @arguments = arguments
      @job_id    = SecureRandom.uuid
    end

    def perform_now
      # Compatibility for ActiveJob interface
      return super if defined?(super)

      perform(*arguments)
    end

    def perform(*)
      raise NotImplementedError
    end
  end
end
