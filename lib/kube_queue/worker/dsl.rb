module KubeQueue
  module Worker
    module DSL
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
    end
  end
end
