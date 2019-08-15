class PrintMessageJob
  include KubeQueue::Worker

  worker_name 'print-message-job'
  image 'ruby'
  container_name 'ruby'

  def perform(payload)
    payload[:message]
  end
end

class MockClient
  def create_job(manifest)
    job = K8s::Resource.new(manifest)
    job.metadata.namespace ||= 'default'
    job
  end

  # overrider on test
  def get_job(_namespace, _name)
    raise NotImplementedError
  end

  # overrider on test
  def list_job(_job_class, _namespace = nil)
    []
  end

  def create_cron_job(manifest)
    cron_job = K8s::Resource.new(manifest)
    cron_job.metadata.namespace ||= 'default'
    cron_job
  end
end

class MockExecutor < KubeQueue::Executor
  def enqueue(job)
    resource = super

    job.perform_now

    resource
  end
end

KubeQueue.client = MockClient.new
KubeQueue.executor = MockExecutor.new
