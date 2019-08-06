require 'forwardable'

module KubeQueue
  class JobConfiguration
    extend Forwardable

    attr_reader :job
    attr_accessor :payload, :id

    def_delegators(
      :job,
      :command,
      :job_name,
      :name,
      :container_name,
      :image,
      :command,
      :template,
      :restart_policy,
      :backoff_limit
    )

    def initialize(job, options)
      @job = job
      @options = options
    end

    def backoff_limit
      @options[:backoff_limit] || job.backoff_limit
    end

    def restart_policy
      @options[:restart_policy] || job.restart_policy
    end

    def binding
      super
    end
  end
end
