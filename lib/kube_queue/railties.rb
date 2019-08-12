ActiveSupport.on_load(:active_job) do
  require "active_job/adapters/kube_queue_adapter"
end
