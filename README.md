# KubeQueue

[![Build Status](https://travis-ci.org/yuemori/kube_queue.svg?branch=master)](https://travis-ci.org/yuemori/kube_queue)

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
TestWorker.enqueue(message: 'hello')

# delay
TestWorker.enqueue_at(message: 'hello', Time.now + 100)
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

See more examples in [here](examples/myapp/app/jobs).

### Run job on locally

```
bundle exec kube_queue runner JOB_NAME [PAYLOAD]
```

See more information by `kube_queue help` or read [here](exe/kube_queue).

## Advanced Tips

### Get a job status

```ruby
job = ComputePiJob.perform_later
job.status
```

scheduled job dosent supported now.

### Check a generating manifest

```ruby
# from class
puts ComputePiJob.manifest

# from instance
job = ComputePiJob.perform_later
puts job.manifest
```

### Retry job

Kubernetes Job has a own retry mechanism, if set backoff_limit and/or restart_policy to use it.

```ruby
class ComputePiJob
  include KubeQueue::Worker

  worker_name 'pi'
  image 'perl'
  container_name 'pi'
  command "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"

  backoff_limit 10
  restart_policy 'Never'
end
```

More information, see the official document [here](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#pod-backoff-failure-policy).

### Timeout

Kubernetes Job has a own timeout mechanism, if set the active_deadline_seconds to use it.

```ruby
class ComputePiJob
  include KubeQueue::Worker

  worker_name 'pi'
  image 'perl'
  container_name 'pi'
  command "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"

  active_deadline_seconds 300
end
```

More information, see the official document [here](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#job-termination-and-cleanup).

### Managing container resources

When you specify a Pod, you can optional specify hou much CPU and memory container needs.

```ruby
class ComputePiJob
  include KubeQueue::Worker

  worker_name 'pi'
  image 'perl'
  container_name 'pi'
  command "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"

  cpu_limit '0.3'
  cpu_request '0.2'
  memory_limit '100m'
  memory_request '50m'
end
```

More information, see the official document [here](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/).

### Use environment variable from ConfigMap/Secret

```ruby
class ComputePiJob
  include KubeQueue::Worker

  worker_name 'pi'
  image 'perl'
  container_name 'pi'
  command "perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"

  env_from_secret 'mysecret1', 'mysecret2'
  env_from_config_map 'myapp'
end
```

## Features

- Add tests.
- Support multiple kubernetes client configuration.
- Logging informations.
- Support to get CronJob status.

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

irb(main):001:0> TestWorker.enqueue(message: 'hello, kubernetes!')
```
