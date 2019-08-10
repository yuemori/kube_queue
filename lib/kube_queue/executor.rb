require 'erb'
require 'json'

module KubeQueue
  class Executor
    def perform_async(job, body)
      manifest = job.build_manifest(body)
      KubeQueue.client.create_job(manifest)
    end
  end
end
