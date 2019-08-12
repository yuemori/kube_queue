KubeQueue.kubernetes_configure do |client|
  client.url = ENV['K8S_URL']
  client.ssl_ca_file = ENV['K8S_CA_CERT_FILE']
  client.auth_token = ENV['K8S_TOKEN']
end
