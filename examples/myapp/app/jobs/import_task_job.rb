class ImportTaskJob < ApplicationJob
  include KubeQueue::Worker

  worker_name 'import-task'
  image "gcr.io/#{ENV['PROJECT_ID']}/kube-queue-test-app"
  container_name 'kube-queue-test-app'

  env_from_secret 'myapp'
  env_from_config_map 'myapp'

  def perform(csv)
    Task.transaction do
      csv.each do |row|
        Task.create!(name: row[0], state: row[1])
      end
    end
  end
end
