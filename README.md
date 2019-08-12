# KubeQueue

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

  job_name 'kube-queue-test'
  image "my-registry/my-image"
  container_name 'kube-queue-test'

  command 'bundle', 'exec', 'kube_queue', 'TestWorker', '-r', './test_worker.rb'

  def perform(payload)
    puts payload['message']
  end
end
```

Setting kubernetes configuration.

```ruby
KubeQueue.kubernetes_configure do |client|
  client.url = ENV['K8S_URL']
  client.ssl_ca_file = ENV['K8S_CA_CERT_FILE']
  client.auth_token = File.read(ENV['K8S_TOKEN'])
end
```

and run:

```ruby
TestWorker.perform(message: 'hello')
```

### ActiveJob Support

Write to `application.rb`:

```ruby
Rails.application.config.active_job.adapter = :kube_queue
```

Just put your job into `app/jobs` . Example:

```ruby
# app/jobs/print_message_job.rb
class PrintMessageJob < ApplicationJob
  include KubeQueue::Worker

  worker_name 'print-message-job'
  image "your-registry/your-image"
  container_name 'your-container-name'

  def perform(payload)
    logger.info payload[:message]
  end
end
```

and run:

```ruby
irb(main):001:0> job = PrintMessageJob.perform_later(message: 'hello, kubernetes!')
Enqueued PrintMessageJob (Job ID: 0bf15b35-62d8-4380-9173-99839ce735ff) to KubeQueue(default) with arguments: {:message=>"hello, kubernetes!"}
=> #<PrintMessageJob:0x00007fbfd00c7848 @arguments=[{:message=>"hello, kubernetes!"}], @job_id="0bf15b35-62d8-4380-9173-99839ce735ff", @queue_name="default", @priority=nil, @executions=0>
irb(main):002:0> job.status
=> #<K8s::Resource startTime="2019-08-12T15:56:37Z", active=1>
irb(main):003:0> job.status
=> #<K8s::Resource conditions=[{:type=>"Complete", :status=>"True", :lastProbeTime=>"2019-08-12T15:57:03Z", :lastTransitionTime=>"2019-08-12T15:57:03Z"}], startTime="2019-08-12T15:56:37Z", completionTime="2019-08-12T15:57:03Z", succeeded=1>
```

See more examples in [here](examples).

### Run job on locally

```
bundle exec kube_queue runner JOB_NAME [PAYLOAD]
```

See more information by `kube_queue help` or [here](exe/kube_queue).

## Features

- Add tests.
- Support multiple kubernetes client configuration.
- Logging informations.

## Development(on GCP/GKE)

setup:

```
# create service account and cluster role.
kubectl apply -f examples/k8s/service-account.yaml

# get ca.crt and token
kubectl get secret -n kube-system kube-queue-test-token-xxx -o jsonpath="{['data']['token']}" | base64 -d > secrets/token
kubectl get secret -n kube-system kube-queue-test-token-xxx -o jsonpath="{['data']['ca\.crt']}" | base64 -d > secrets/ca.crt

# build image
gcloud builds submit --config cloudbuild.yaml .
```

run:

```
K8S_URL=https://xx.xxx.xxx.xxx K8S_CA_CERT_FILE=$(pwd)/secrets/ca.crt K8S_TOKEN=$(pwd)/secrets/token IMAGE_NAME=gcr.io/your-project/kube-queue bin/console

irb(main):001:0> TestWorker.perform_async(message: 'hello, kubernetes!')
```
