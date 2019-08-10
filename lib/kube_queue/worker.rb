require 'erb'
require 'yaml'
require 'kube_queue/job_configuration'

module KubeQueue
  module Worker
    def self.included(base)
      base.extend(ClassMethods)

      KubeQueue.register_worker(base.name, base)
    end

    module ClassMethods
      def job_name(name)
        @job_name = name
      end

      def container_name(container_name)
        @container_name = container_name
      end

      def image(image)
        @image = image
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

      def backoff_limit(limit)
        @backoff_limit = limit
      end

      def build_manifest(body)
        spec = JobSpecification.new.configure do |s|
          s.id = SecureRandom.uuid
          s.image = @image
          s.name = name
          s.command = @command
          s.job_name = @job_name
          s.container_name = @job_name
          s.template = @template
          s.backoff_limit = @backoff_limit
          s.payload = JSON.generate(body, quirks_mode: true)
        end

        spec.to_manifest
      end

      def perform_sync(body)
        new.perform(body)
      end

      def perform_async(body)
        KubeQueue.executor.perform_async(self, body)
      end
    end
  end
end
