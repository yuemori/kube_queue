class ComputePiJob < ApplicationJob
  include KubeQueue::Worker

  worker_name 'pi'
  image 'perl'
  container_name 'pi'
  command "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"

  cpu_limit '0.3'
  cpu_request '0.2'
  memory_limit '100m'
  memory_request '50m'
end
