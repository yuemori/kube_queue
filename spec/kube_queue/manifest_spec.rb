require 'spec_helper'
require 'erbh'

RSpec.describe 'KubeQueue generated manifest' do
  include ERBh

  class TestWorker
    include KubeQueue::Worker

    worker_name 'test-worker'
    image 'test-image'
  end

  let(:job) { TestWorker.new }

  let(:manifest) { job.manifest }

  describe 'default' do
    it 'matches default manifest' do
      expect(manifest).to match YAML.safe_load(erbh(<<~ERB, job_id: job.job_id))
        apiVersion: batch/v1
        kind: Job
        metadata:
          annotations:
            kube-queue-job-class: "TestWorker"
            kube-queue-job-id: "<%= @job_id %>"
            kube-queue-job-payload: '[]'
          name: "test-worker-<%= @job_id %>"
          namespace: default
          labels:
            kube-queue-job: "true"
            kube-queue-worker-name: "test-worker"
            kube-queue-job-class: "TestWorker"
            kube-queue-job-id: "<%= @job_id %>"
        spec:
          template:
            metadata:
              annotations:
                kube-queue-job-class: "TestWorker"
                kube-queue-job-id: "<%= @job_id %>"
                kube-queue-job-payload: '[]'
              labels:
                kube-queue-job: "true"
                kube-queue-worker-name: "test-worker"
                kube-queue-job-class: "TestWorker"
                kube-queue-job-id: "<%= @job_id %>"
            spec:
              containers:
              - name: "test-worker"
                image: "test-image"
                command: ["bundle", "exec", "kube_queue", "runner", "TestWorker"]
                env:
                - name: "KUBE_QUEUE_MESSAGE_PAYLOAD"
                  value: '[]'
              resources: {}
              restartPolicy: "Never"
      ERB
    end
  end

  describe 'payload' do
    let(:job) { TestWorker.new(test: true) }

    subject(:env) { manifest['spec']['template']['spec']['containers'][0]['env'] }

    it 'sets to KUBE_QUEUE_MESSAGE_PAYLOAD' do
      expect(env).to include(
        "name" => "KUBE_QUEUE_MESSAGE_PAYLOAD",
        "value" => "[#{{ test: true }.to_json}]"
      )
    end
  end

  describe 'env' do
    before do
      TestWorker.env(
        TEST: true,
        RAILS_ENV: "production"
      )
    end

    after do
      TestWorker.env(nil)
    end

    subject(:env) { manifest['spec']['template']['spec']['containers'][0]['env'] }

    it 'includes env' do
      expect(env).to match_array(
        [
          {
            "name" => "KUBE_QUEUE_MESSAGE_PAYLOAD",
            "value" => "[]"
          },
          {
            "name" => "TEST",
            "value" => "true"
          },
          {
            "name" => "RAILS_ENV",
            "value" => "production"
          }
        ]
      )
    end
  end

  describe 'template' do
    before do
      TestWorker.template = File.expand_path('../../template/test.yaml', __FILE__)
    end

    it 'matches test manifest' do
      expect(manifest).to match YAML.safe_load(erbh(<<~ERB, job_id: job.job_id))
        apiVersion: batch/v1
        kind: Job
        metadata:
          annotations:
            kube-queue-job-class: "TestWorker"
            kube-queue-job-id: "<%= @job_id %>"
            kube-queue-job-payload: '[]'
          name: "test-worker-<%= @job_id %>"
          namespace: default
          labels:
            kube-queue-job: "true"
            kube-queue-worker-name: "test-worker"
            kube-queue-job-class: "TestWorker"
            kube-queue-job-id: "<%= @job_id %>"
        spec:
          template:
            metadata:
              annotations:
                kube-queue-job-class: "TestWorker"
                kube-queue-job-id: "<%= @job_id %>"
                kube-queue-job-payload: '[]'
              labels:
                kube-queue-job: "true"
                kube-queue-worker-name: "test-worker"
                kube-queue-job-class: "TestWorker"
                kube-queue-job-id: "<%= @job_id %>"
            spec:
              containers:
              - name: "test-worker"
      ERB
    end

    after do
      TestWorker.template = nil
    end
  end
end
