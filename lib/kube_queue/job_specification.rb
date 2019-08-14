require 'erb'
require 'yaml'

module KubeQueue
  class JobSpecification
    class MissingParameterError < StandardError; end

    attr_reader :job_class

    attr_accessor :payload, :name, :active_deadline_seconds, :backoff_limit

    attr_writer :image, :namespace, :worker_name, :command,
      :container_name, :restart_policy, :job_labels, :pod_labels,
      :env_from_config_map, :env_from_secret

    def initialize(job_class)
      @job_class = job_class
    end

    def job_name(job_id)
      "#{worker_name}-#{job_id}"
    end

    def image
      @image || raise_not_found_required_parameter('image')
    end

    def namespace
      @namespace || 'default'
    end

    def worker_name
      @worker_name || raise_not_found_required_parameter('worker_name')
    end

    def container_name
      @container_name || worker_name
    end

    def command
      @command || ['bundle', 'exec', 'kube_queue', 'runner', job_class.name]
    end

    def restart_policy
      @restart_policy || 'Never'
    end

    def job_labels
      @job_labels || {}
    end

    def pod_labels
      @pod_labels || {}
    end

    def env
      KubeQueue.default_env.merge(@env || {})
    end

    def env_from_config_map
      @env_from_config_map || []
    end

    def env_from_secret
      @env_from_config_map || []
    end

    def env_from_exists?
      !env_from_config_map.empty? && !env_from_secret.empty?
    end

    def raise_not_found_required_parameter(field)
      raise MissingParameterError, "#{field} is required"
    end
  end
end
