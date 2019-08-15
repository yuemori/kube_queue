class ArchiveDoneTasksJob < ApplicationJob
  include KubeQueue::Worker

  worker_name 'archive-done-task'
  image "gcr.io/#{ENV['PROJECT_ID']}/kube-queue-test-app"
  container_name 'kube-queue-test-app'

  env_from_secret 'myapp'
  env_from_config_map 'myapp'

  def perform
    Task.transaction do
      count = Task.done.delete_all
      logger.info "#{count} tasks were deleted."
    end
  end
end
