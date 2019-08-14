module KubeQueue
  module Worker
    module DSL
      def job_spec
        @job_spec ||= JobSpecification.new(self)
      end

      def worker_name(name)
        job_spec.worker_name = name
      end

      def container_name(container_name)
        job_spec.container_name = container_name
      end

      def image(image)
        job_spec.image = image
      end

      def namespace(namespace)
        job_spec.namespace = namespace
      end

      def command(*command)
        job_spec.command = command
      end

      def restart_policy(policy)
        job_spec.restart_policy = policy
      end

      def active_deadline_seconds(seconds)
        job_spec.active_deadline_seconds = seconds
      end

      def backoff_limit(limit)
        job_spec.backoff_limit = limit
      end

      def env(env)
        job_spec.env = env
      end

      def labels(labels)
        job_spec.labels = labels
      end

      def env_from_config_map(*config_map_names)
        job_spec.env_from_config_map = config_map_names
      end

      def env_from_secret(*secret_names)
        job_spec.env_from_config_map = secret_names
      end
    end
  end
end
