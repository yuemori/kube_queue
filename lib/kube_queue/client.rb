require 'k8s-client'
require 'pathname'

module KubeQueue
  class Client
    def create_job(manifest)
      job = K8s::Resource.new(manifest)
      job.metadata.namespace ||= 'default'
      client.api('batch/v1').resource('jobs').create_resource(job)
    end

    def get_job(namespace, name)
      client.api('batch/v1').resource('jobs', namespace: namespace).get(name)
    end

    def list_job(job_class, namespace = nil)
      selector = { 'kube-queue-job': 'true', 'kube-queue-job-class': job_class }
      client.api('batch/v1').resource('jobs', namespace: namespace).list(labelSelector: selector)
    end

    def create_cron_job(manifest)
      cron_job = K8s::Resource.new(manifest)
      cron_job.metadata.namespace ||= 'default'
      client.api('batch/v1beta1').resource('cronjobs').create_resource(cron_job)
    end

    attr_accessor :url, :ssl_ca_file, :auth_token

    private

    def client
      @client ||= K8s.client(url, ssl_ca_file: ssl_ca_file, auth_token: auth_token)
    end
  end
end
