require 'k8s-client'
require 'pathname'

module KubeQueue
  class Client
    def create_job(manifest)
      job = K8s::Resource.new(manifest)
      job.metadata.namespace = 'default'
      client.api('batch/v1').resource('jobs').create_resource(job)
    end

    attr_accessor :url, :ssl_ca_file, :auth_token

    private

    def client
      @client ||= K8s.client(url, ssl_ca_file: ssl_ca_file, auth_token: auth_token)
    end
  end
end
