require 'logger'
require 'json'

module KubeQueue
  class Runner
    def initialize(job_name)
      @job_name = job_name
    end

    def run(payload)
      payload = JSON.parse(payload) if payload

      worker = KubeQueue.fetch_worker(@job_name).new
      payload ? worker.new.perform(payload) : worker.new.perform
    end
  end
end
