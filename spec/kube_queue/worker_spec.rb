require 'spec_helper'
require 'pry-byebug'

RSpec.describe KubeQueue::Worker do
  describe '.enqueue' do
    subject(:job) { PrintMessageJob.enqueue(arg) }

    let(:arg) { { message: 'hello' } }

    before do
      expect_any_instance_of(PrintMessageJob).to receive(:perform).with(arg)
      expect(KubeQueue.client).to receive(:create_job).and_call_original
    end

    it { expect { subject }.not_to raise_error }
    it { expect(job.arguments).to eq [arg] }
  end

  describe '.enqueue_at' do
    subject(:job) { PrintMessageJob.enqueue_at(arg, timestamp) }

    let(:arg) { { message: 'hello' } }
    let(:timestamp) { Time.utc(2019, 8, 15, 18, 30, 0).to_i }

    before do
      expect_any_instance_of(PrintMessageJob).to receive(:perform).with(arg)
      expect(KubeQueue.client).to receive(:create_cron_job).and_call_original
    end

    it { expect { subject }.not_to raise_error }
    it { expect(job.arguments).to eq [arg] }
    it { expect(job.scheduled_at).to eq timestamp }
    it { expect(job.resource.spec.schedule).to eq "30 18 15 08 4" }

    context 'when given timezone is not utc' do
      let(:timestamp) { Time.new(2019, 8, 15, 18, 30, 0, "+09:00").to_i }

      it { expect(job.resource.spec.schedule).to eq "30 09 15 08 4" }
    end
  end

  describe '#manifest' do
    subject { job.manifest }

    include ERBh

    let(:job) { PrintMessageJob.new(message: 'hello') }

    # rubocop:disable Layout/TrailingWhitespace
    let(:job_manifest) do
      YAML.safe_load(erbh(<<~MANIFEST, job_id: job.job_id, payload: JSON.generate([{ message: 'hello' }], quirks_mode: true)))
        ---
        apiVersion: batch/v1
        kind: Job
        metadata:
          annotations:
            kube-queue-job-class: PrintMessageJob
            kube-queue-job-id: <%= @job_id %>
            kube-queue-job-payload: '<%= @payload %>'
          name: print-message-job-<%= @job_id %>
          namespace: default
          labels:
            kube-queue-job: 'true'
            kube-queue-worker-name: print-message-job
            kube-queue-job-class: PrintMessageJob
            kube-queue-job-id: <%= @job_id %>
        spec:
          template:
            metadata:
              annotations:
                kube-queue-job-class: PrintMessageJob
                kube-queue-job-id: <%= @job_id %>
                kube-queue-job-payload: '<%= @payload %>'
              labels:
                kube-queue-job: 'true'
                kube-queue-worker-name: print-message-job
                kube-queue-job-class: PrintMessageJob
                kube-queue-job-id: <%= @job_id %>
            spec:
              containers:
              - name: ruby
                image: ruby
                command:
                - bundle
                - exec
                - kube_queue
                - runner
                - PrintMessageJob
                env:
                - name: KUBE_QUEUE_MESSAGE_PAYLOAD
                  value: '<%= @payload %>'
              resources: {}
              restartPolicy: Never
          backoffLimit: 
          activeDeadlineSeconds: 
      MANIFEST
    end
    # rubocop:enable Layout/TrailingWhitespace

    context 'when job' do
      it { is_expected.to eq job_manifest }
    end

    context 'when cronjob' do
      before { job.scheduled_at = timestamp }

      let(:timestamp) { Time.utc(2019, 8, 15, 18, 30).to_i }

      let(:cron_job_manifest) do
        {
          apiVersion: "batch/v1beta1",
          kind: "CronJob",
          metadata: job_manifest["metadata"],
          spec: {
            startingDeadlineSeconds: nil,
            concurrentPolicy: "Allow",
            schedule: "30 18 15 08 4",
            jobTemplate: {
              spec: job_manifest["spec"]
            }
          }
        }
      end

      it { is_expected.to eq cron_job_manifest }
    end
  end
end
