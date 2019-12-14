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

      attr_writer :template

      def template
        @template ||= File.expand_path('../../../template/job.yaml', __FILE__)
      end

      def active_job?
        defined?(ActiveJob) && ancestors.include?(ActiveJob::Base)
      end

      def list
        namespace = job_spec.namespace

        KubeQueue.client.list_job(job_spec.job_class, namespace).map do |res|
          worker = KubeQueue.fetch_worker(res.metadata.annotations['kube-queue-job-class'])
          job = worker.new(*payload)
          job.resource = res
          job
        end
      end

      def find(job_id)
        namespace = job_spec.namespace

        name = job_spec.job_name(job_id)

        res = KubeQueue.client.get_job(namespace, name)
        worker = KubeQueue.fetch_worker(res.metadata.annotations['kube-queue-job-class'])

        payload = deserialize_annotation_payload(res.metadata.annotations['kube-queue-job-payload'])

        job = worker.new(*payload)
        job.resource = res
        job
      end

      def enqueue(*args)
        job = new(*args)
        KubeQueue.executor.enqueue(job)
        job
      end
      alias_method :perform_async, :enqueue

      def enqueue_at(*args)
        args = args.dup
        timestamp = args.pop
        job = new(*args)
        job.scheduled_at = timestamp
        KubeQueue.executor.enqueue(job)
        job
      end

      def read_template
        File.read(template)
      end

      def manifest
        new.manifest
      end

      private

      def deserialize_annotation_payload(payload)
        return payload if payload.empty?

        payload = JSON.parse(payload)

        # Compatibility for ActiveJob serialized payload
        payload = [payload] unless payload.is_a?(Array)

        payload = ActiveJob::Arguments.deserialize(payload) if defined?(ActiveJob::Arguments)

        payload
      end
    end

    def read_template
      self.class.read_template
    end

    def job_spec
      self.class.job_spec
    end

    attr_accessor :job_id, :scheduled_at
    attr_reader :arguments, :resource

    alias_method :payload, :arguments

    def initialize(*arguments)
      # Compatibility for ActiveJob interface
      if method(__method__).super_method.arity.zero?
        super()
      else
        super
      end

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

    def manifest
      if scheduled_at
        # Kubernetes CronJob does not support timezone
        cron = Time.at(scheduled_at).utc.strftime("%M %H %d %m %w")
        ManifestBuilder.new(self).build_cron_job(cron)
      else
        ManifestBuilder.new(self).build_job
      end
    end

    def serialized_payload
      if self.class.active_job?
        ActiveJob::Arguments.serialize(arguments)
      else
        arguments
      end
    end

    def resource=(resource)
      @resource = resource
      self.job_id = resource.metadata.annotations['kube-queue-job-id']
    end

    private

    def load_target
      self.resource = KubeQueue.client.get_job(job_spec.namespace, job_spec.job_name(job_id))
      @loaded = true
    end
  end
end
