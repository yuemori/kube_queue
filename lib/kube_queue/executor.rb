require 'kube_queue/manifest_builder'

module KubeQueue
  class Executor
    def enqueue(job)
      resource = if job.scheduled_at
                   KubeQueue.client.create_cron_job(job.manifest)
                 else
                   KubeQueue.client.create_job(job.manifest)
                 end

      job.resource = resource
      resource
    end
  end
end
