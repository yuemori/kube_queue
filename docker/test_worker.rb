require 'kube_queue'

class TestWorker
  include KubeQueue::Worker

  job_name_as 'kube-queue-test'
  image_as ENV['IMAGE_NAME']
  container_name_as 'kube-queue-test'

  command_as 'bundle', 'exec', 'kube_queue', 'TestWorker', '-r', './test_worker.rb'

  def perform(payload)
    puts payload['message']
  end
end
