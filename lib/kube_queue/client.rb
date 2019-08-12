require 'k8s-client'
require 'pathname'

module KubeQueue
  class Client
    def create_job(manifest)
      job = K8s::Resource.new(manifest)
      job.metadata.namespace ||= 'default'
      client.resource('jobs').create_resource(job)
    end

    def get_job(namespace, name)
      client.resource('jobs', namespace: namespace).get(name)
    end

    def list_job(namespace = nil)
      selector = { 'kube-queue-job': 'true' }
      client.resource('jobs', namespace: namespace).list(labelSelector: selector)
    end

    attr_accessor :url, :ssl_ca_file, :auth_token

    private

    def client
      @client ||= K8s.client(url, ssl_ca_file: ssl_ca_file, auth_token: auth_token).api('batch/v1')
    end
  end
end
