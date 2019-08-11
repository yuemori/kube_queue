require 'kube_queue/job_specification'

module KubeQueue
  module Worker
    def self.included(base)
      base.extend(ClassMethods)

      KubeQueue.register_worker(base.name, base)
    end

    module ClassMethods
      def worker_name(name)
        @worker_name = name
      end

      def container_name(container_name)
        @container_name = container_name
      end

      def image(image)
        @image = image
      end

      def namespace(namespace)
        @namespace = namespace
      end

      def command(*command)
        @command = command
      end

      def template(template)
        @template = template
      end

      def restart_policy(policy)
        @restart_policy = policy
      end

      def active_deadline_seconds(seconds)
        @active_deadline_seconds = seconds
      end

      def backoff_limit(limit)
        @backoff_limit = limit
      end

      def labels(labels)
        @labels = labels
      end

      def build_specification(body)
        JobSpecification.new.configure do |s|
          s.id = SecureRandom.uuid
          s.labels = @labels
          s.image = @image
          s.name = name
          s.namespace = @namespace
          s.command = @command
          s.worker_name = @worker_name
          s.container_name = @container_name
          s.template = @template
          s.backoff_limit = @backoff_limit
          s.active_deadline_seconds = @active_deadline_seconds
          s.payload = JSON.generate(body, quirks_mode: true) if body
        end
      end

      def perform_sync(body)
        new.perform(body)
      end

      def perform_async(body = nil)
        KubeQueue.executor.perform_async(self, body)
      end
    end
  end
end
