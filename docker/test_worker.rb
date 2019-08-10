require 'kube_queue'

class TestWorker
  include KubeQueue::Worker

  job_name 'kube-queue-test'
  image ENV['IMAGE_NAME']
  container_name 'kube-queue-test'
  command 'bundle', 'exec', 'kube_queue', 'TestWorker', '-r', './test_worker.rb'

  def perform(payload)
    puts payload['message']
  end
end
