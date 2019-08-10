require 'forwardable'

module KubeQueue
  class JobSpecification
    extend Forwardable

    attr_accessor :payload, :id, :name

    attr_writer :image, :job_name, :command, :container_name, :template, :backoff_limit, :restart_policy

    def configure
      yield self
      self
    end

    def backoff_limit
      @backoff_limit || 0
    end

    def restart_policy
      @restart_policy || 'Never'
    end

    def command
      @command || ['bundle', 'exec', 'kube_queue', name]
    end

    def image
      @image || raise
    end

    def job_name
      @job_name || raise
    end

    def container_name
      @container_name || raise
    end

    def template
      @template || File.read(File.expand_path('../../../template/job.yaml', __FILE__))
    end

    def to_manifest
      YAML.safe_load(ERB.new(template, nil, "%").result(binding))
    end

    private

    def binding
      super
    end
  end
end
