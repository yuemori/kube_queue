require 'logger'
require 'json'

module KubeQueue
  class Runner
    def initialize(job_name)
      @job_name = job_name
    end

    def run(payload)
      payload = JSON.parse(payload)

      worker = KubeQueue.fetch_worker(@job_name)
      worker.new.perform(payload)
    end
  end
end
