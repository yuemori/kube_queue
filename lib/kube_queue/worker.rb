require 'kube_queue/worker/dsl'
require 'kube_queue/job_specification'

module KubeQueue
  module Worker
    def self.included(base)
      base.extend(ClassMethods)

      KubeQueue.register_worker(base.name, base)
    end

    module ClassMethods
      include DSL

      def list
        namespace = job_spec.namespace

        KubeQueue.client.list_job(job_spec.job_class, namespace).map do |res|
          worker = KubeQueue.fetch_worker(res.metadata.annotations['kube-queue-job-class'])
          job_id = res.metadata.annotations['kube-queue-job-id']
          payload = deserialize_annotation_payload(res.metadata.annotations['kube-queue-message-payload'])

          job = worker.new(*payload)
          job.job_id = job_id
          job.resource = res
          job
        end
      end

      def find(job_id)
        namespace = job_spec.namespace

        name = job_spec.job_name(job_id)

        res = KubeQueue.client.get_job(name, namespace)
        worker = KubeQueue.fetch_worker(res.metadata.annotations['kube-queue-job-class'])
        job_id = res.metadata.annotations['kube-queue-job-id']
        payload = deserialize_annotation_payload(res.metadata.annotations['kube-queue-message-payload'])

        job = worker.new(*payload)
        job.job_id = job_id
        job.resource = res
        job
      end

      def enqueue(body = nil)
        KubeQueue.executor.enqueue(new, body)
      end
      alias_method :perform_async, :enqueue

      def enqueue_at(body = nil)
        KubeQueue.executor.enqueue(new, body)
      end

      def read_template
        File.read(@template || File.expand_path('../../../template/job.yaml', __FILE__))
      end

      private

      def deserialize_annotation_payload(payload)
        return payload if payload.empty?

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

    def template
      self.class.read_template
    end

    def job_spec
      self.class.job_spec
    end

    attr_accessor :job_id, :arguments, :resource

    def initialize(*arguments)
      # Compatibility for ActiveJob interface
      super

      @arguments = arguments
      @job_id    = SecureRandom.uuid
      @loaded    = false
    end

    def perform_now
      # Compatibility for ActiveJob interface
      return super if defined?(super)

      perform(*arguments)
    end

    def perform(*)
      raise NotImplementedError
    end

    # FIXME: improve performance
    def status
      return @resource.status if loaded?

      load_target

      @resource.status
    end

    def loaded?
      @loaded
    end

    def reload!
      @loaded = false
      @resource = nil

      load_target
    end

    private

    def load_target
      @rsource = KubeQueue.client.get_job(job_spec.namespace, job_spec.job_name(job_id))
      @loaded = true
    end
  end
end
