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
      def job_name_as(name)
        @job_name = name
      end

      def job_name
        @job_name || raise
      end

      def container_name
        @container_name || raise
      end

      def container_name_as(container_name)
        @container_name = container_name
      end

      def image
        @image || raise
      end

      def image_as(image)
        @image = image
      end

      def command_as(*command)
        @command = command
      end

      def command
        @command || ['bundle', 'exec', 'kube_queue', name]
      end

      def template_as(template)
        @template = template
      end

      def template
        @template || File.read(File.expand_path('../../../template/job.yaml', __FILE__))
      end

      def restart_policy
        @restart_policy || 'Never'
      end

      def backoff_limit
        @backoff_limit || 0
      end

      def build_manifest(body, options)
        config = JobConfiguration.new(self, options)

        config.id = SecureRandom.uuid
        config.payload = JSON.generate(body, quirks_mode: true)

        YAML.safe_load(ERB.new(template, nil, "%").result(config.binding))
      end

      def perform_sync(body)
        new.perform(body)
      end

      def perform_async(body, options = {})
        KubeQueue.executor.perform_async(self, body, options)
      end
    end
  end
end
