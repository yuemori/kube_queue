require 'kube_queue/manifest_builder'

module KubeQueue
  class Executor
    def enqueue(job)
      if job.scheduled_at
        KubeQueue.client.create_cron_job(job.manifest)
      else
        KubeQueue.client.create_job(job.manifest)
      end
    end
  end
end
