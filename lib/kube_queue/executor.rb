require 'kube_queue/manifest_builder'

module KubeQueue
  class Executor
    def enqueue(job, payload)
      manifest = ManifestBuilder.new(job, payload).build_job
      KubeQueue.client.create_job(manifest)
    end

    def enqueue_at(job, payload, timestamp)
      cron = Time.at(timestamp).utc.strftime("%M %H %d %m %w")
      manifest = ManifestBuilder.new(job, payload).build_cron_job(cron)
      KubeQueue.client.create_cron_job(manifest)
    end
  end
end
