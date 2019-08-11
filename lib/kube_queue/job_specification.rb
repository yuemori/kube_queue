require 'erb'
require 'yaml'

module KubeQueue
  class JobSpecification
    class MissingParameterError < StandardError; end

    attr_accessor :payload, :id, :name

    attr_reader :active_deadline_seconds, :backoff_limit

    attr_writer :image, :namespace, :worker_name, :command, :container_name,
      :template, :backoff_limit, :restart_policy, :labels, :active_deadline_seconds

    def configure
      yield self
      self
    end

    def restart_policy
      @restart_policy || 'Never'
    end

    def command
      @command || ['bundle', 'exec', 'kube_queue', name]
    end

    def image
      @image || raise_not_found_required_parameter('image')
    end

    def worker_name
      @worker_name || raise_not_found_required_parameter('worker_name')
    end

    def namespace
      @namespace || 'default'
    end

    def labels
      (@labels || {}).merge(worker_name: worker_name, id: id)
    end

    def container_name
      @container_name || @worker_name || raise_not_found_required_parameter('container_name')
    end

    def template
      @template || File.read(File.expand_path('../../../template/job.yaml', __FILE__))
    end

    def to_manifest
      YAML.safe_load(ERB.new(template, nil, "-").result(binding))
    end

    private

    def raise_not_found_required_parameter(field)
      raise MissingParameterError, "#{field} is required"
    end
  end
end
