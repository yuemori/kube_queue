class ImportTaskJob < ApplicationJob
  include KubeQueue::Worker

  worker_name 'print-message-job'
  image "gcr.io/#{ENV['PROJECT_ID']}/kube-queue-test-app"
  container_name 'kube-queue-test-app'

  def perform(tasks)
    Task.transaction do
      tasks.each(&:save!)
    end
  end
end
