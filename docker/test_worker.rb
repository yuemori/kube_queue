require 'kube_queue'

class TestWorker
  include KubeQueue::Worker

  worker_name 'kube-queue-test'
  image ENV['IMAGE_NAME']
  container_name 'kube-queue-test'
  command 'bundle', 'exec', 'kube_queue', 'runner', 'TestWorker', '-r', './test_worker.rb'

  def perform(payload)
    puts payload['message']
  end
end

# Run official example.
# see: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/
class TestWorker2
  include KubeQueue::Worker

  worker_name 'pi'
  image 'perl'
  container_name 'pi'
  command "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"
end
