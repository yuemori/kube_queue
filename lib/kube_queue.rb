require "kube_queue/version"
require "kube_queue/executor"
require "kube_queue/configuration"
require "kube_queue/worker"
require "kube_queue/client"
require "active_job/adapters/kube_queue_adapter" if defined?(Rails)

module KubeQueue
  class Error < StandardError; end

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
  end
end
