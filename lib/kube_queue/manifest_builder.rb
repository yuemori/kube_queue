require 'erb'
require 'json'

module KubeQueue
  class ManifestBuilder
    attr_reader :job

    def initialize(job, payload = nil)
      @job = job
      @payload = payload
    end

    def spec
      job.job_spec
    end

    def payload
      @payload ? JSON.generate(@payload, quirks_mode: true) : nil
    end

    def build
      YAML.safe_load(ERB.new(job.template, nil, "-").result(binding))
    end
  end
end
