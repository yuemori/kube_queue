require 'kube_queue/manifest_builder'

module KubeQueue
  class Executor
    def enqueue(job, payload)
      manifest = ManifestBuilder.new(job, payload).build
      KubeQueue.client.create_job(manifest)
    end
  end
end
