require 'erb'
require 'json'

module KubeQueue
  class Executor
    def perform_async(job, body, options)
      manifest = job.build_manifest(body, options)
      KubeQueue.client.create_job(manifest)
    end
  end
end
