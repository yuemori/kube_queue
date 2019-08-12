class ComputePiJob < ApplicationJob
  include KubeQueue::Worker

  worker_name 'pi'
  image 'perl'
  container_name 'pi'
  command "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"
end
