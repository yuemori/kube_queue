require 'spec_helper'

RSpec.describe KubeQueue::Worker do
  describe 'perform_async' do
    subject { worker.perform_async(body) }

    include ERBh

    let(:worker) do
      Class.new do
        include KubeQueue::Worker

        job_name_as 'test-job'
        container_name_as :test
        image_as 'ruby:2.6.3'

        def self.name
          'TestWorker'
        end
      end
    end

    let(:dummy_executor) do
      Class.new do
        def perform_async(job, body, options)
          job.build_manifest(body, options)
        end
      end
    end

    let(:id) { 'xxx-xxx-xxx-xxx' }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(id)
      executor = dummy_executor.new
      KubeQueue.executor = executor
    end

    after do
      KubeQueue.executor = KubeQueue.default_executor
    end

    let!(:body) { { message: 'hello' } }

    let(:actual_manifest) do
      erbh(<<~ERB, body: JSON.generate(body, quirks_mode: true), id: id)
        apiVersion: batch/v1
        kind: Job
        metadata:
          name: "test-job-<%= @id %>"
        spec:
          template:
            spec:
              containers:
              - name: "test"
                image: "ruby:2.6.3"
                command: ["bundle", "exec", "kube_queue",  "TestWorker"]
                env:
                - name: "KUBE_QUEUE_MESSAGE_PAYLOAD"
                  value: '<%= @body %>'
              restartPolicy: "Never"
          backoffLimit: 0
      ERB
    end

    it { is_expected.to eq YAML.safe_load(actual_manifest) }
  end
end
