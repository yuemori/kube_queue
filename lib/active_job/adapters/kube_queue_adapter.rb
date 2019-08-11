require 'kube_queue'

module ActiveJob
  module QueueAdapters
    # == KubeQueue adapter for ActiveJob ==
    #
    # To use KubeQueue set the queue_adapter config to +:kube_queue+.
    #   Rails.application.config.active_job.queue_adapter = :kube_queue
    class KubeQueueAdapter
      class << self
        # Interface for ActiveJob 4.2
        def enqueue(job)
          KubeQueue.executor.perform_async(job, ActiveJob::Arguments.serialize(job.arguments))
        end

        def enqueue_at(_job, _timestamp)
          raise NotImplementedError
        end
      end

      # Interface for ActiveJob 5.0
      def enqueue(job, options = {})
        KubeQueueAdapter.enqueue(job, options)
      end

      def enqueue_at(job, timestamp, options = {})
        KubeQueueAdapter.enqueue_at(job, timestamp, options)
      end
    end
  end
end
