# KubeQueue

## Features

- Support multiple kubernetes client configuration.
- Support templating and customization for kubernetes job manifest.
- Job dosen't returns id. Can not track job details from code.
- Logging

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kube_queue'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kube_queue

## Getting Started

Implement worker:

```ruby
class TestWorker
  include KubeQueue::Worker

  job_name_as 'kube-queue-test'
  image_as "my-registry/my-image"
  container_name_as 'kube-queue-test'

  command_as 'bundle', 'exec', 'kube_queue', 'TestWorker', '-r', './test_worker.rb'

  def perform(payload)
    puts payload['message']
  end
end
```

Setting kubernetes configuration and run:

```
KubeQueue.kubernetes_configure do |client|
  client.url = ENV['K8S_URL']
  client.ssl_ca_file = ENV['K8S_CA_CERT_FILE']
  client.auth_token = File.read(ENV['K8S_TOKEN'])
end

TestWorker.perform(message: 'hello')
```

## Development

setup:

```
# create service account and cluster role.
kubectl apply -f k8s/service-account.yaml

# get ca.crt and token
< k get secret -n kube-system kube-queue-test-token-xxx -o jsonpath="{['data']['token']}" | base64 -d > secrets/token
< k get secret -n kube-system kube-queue-test-token-xxx -o jsonpath="{['data']['ca\.crt']}" | base64 -d > secrets/ca.crt

# build image
gcloud builds submit --config cloudbuild.yaml .
```

run:

```
K8S_URL=https://xx.xxx.xxx.xxx K8S_CA_CERT_FILE=$(pwd)/secrets/ca.crt K8S_TOKEN=$(pwd)/secrets/token IMAGE_NAME=gcr.io/your-project/kube-queue bin/console

irb(main):001:0> TestWorker.perform_async(message: 'hello kubernetes')
```
