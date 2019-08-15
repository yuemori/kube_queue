require 'erb'
require 'json'

module KubeQueue
  class ManifestBuilder
    attr_reader :job

    def initialize(job)
      @job = job
    end

    def spec
      job.job_spec
    end

    def payload
      JSON.generate(job.serialized_payload, quirks_mode: true)
    end

    def build_job
      YAML.safe_load(ERB.new(job.read_template, nil, "-").result(binding))
    end

    def build_cron_job(cron)
      template = YAML.safe_load(ERB.new(job.read_template, nil, "-").result(binding))

      {
        apiVersion: "batch/v1beta1",
        kind: "CronJob",
        metadata: template["metadata"],
        spec: {
          startingDeadlineSeconds: job.job_spec.starting_deadline_seconds,
          concurrentPolicy: job.job_spec.concurrent_policy,
          schedule: cron,
          jobTemplate: {
            spec: template["spec"]
          }
        }
      }
    end
  end
end
