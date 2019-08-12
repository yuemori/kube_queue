require "kube_queue/version"
require "kube_queue/executor"
require "kube_queue/configuration"
require "kube_queue/worker"
require "kube_queue/client"
require "active_job/adapters/kube_queue_adapter" if defined?(Rails)

module KubeQueue
  class JobNotFound < StandardError; end

  class << self
    attr_writer :executor

    def executor
      @executor ||= default_executor
    end

    def kubernetes_configure
      yield client
    end

    def client
      @client ||= Client.new
    end

    def default_executor
      Executor.new
    end

    def configure(&block)
      configuration.configure(&block)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def list(namespace = nil)
      client.list_job(namespace).map do |job|
        worker = fetch_worker(job.metadata.annotations['kube-queue-job-class'])
        job_id = job.metadata.annotations['kube-queue-job-id']
        payload = deserialize(job.metadata.annotations['kube-queue-message-payload'])

        job = worker.new(*payload)
        job.job_id = job_id
        job
      end
    end

    attr_writer :default_env

    def default_env
      return @default_env if @default_env

      return {} unless defined?(Rails)

      {
        RAILS_LOG_TO_STDOUT: ENV['RAILS_LOG_TO_STDOUT'],
        RAILS_ENV: ENV['RAILS_ENV']
      }
    end

    def fetch_worker(name)
      worker_registry.fetch(name)
    end

    def register_worker(name, klass)
      worker_registry[name] = klass
    end

    def worker_registry
      @worker_registry ||= {}
    end

    private

    def deserialize(payload)
      return payload if payload.blank?

      payload = JSON.parse(payload)
      # Compatibility for ActiveJob serialized payload
      payload = [payload] unless payload.is_a?(Array)

      if defined?(ActiveJob::Arguments)
        begin
          payload = ActiveJob::Arguments.deserialize(payload)
        rescue ActiveJob::DeserializationError => e
          logger.warn e.message
          logger.warn "#{payload} can not deserialized"
        end
      end

      payload
    rescue JSON::ParseError => e
      logger.warn e.message
      logger.warn "#{payload} can not deserialized"
    end
  end
end
