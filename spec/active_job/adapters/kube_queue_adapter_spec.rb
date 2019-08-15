require 'spec_helper'

require 'active_job'
require "active_job/adapters/kube_queue_adapter"

RSpec.describe ActiveJob::QueueAdapters::KubeQueueAdapter do
  let(:job_class) do
    Class.new(ActiveJob::Base) do
      self.queue_adapter = :kube_queue

      include KubeQueue::Worker

      worker_name 'print-message-job'
      image 'ruby'
      container_name 'ruby'

      def perform(payload)
        payload[:message]
      end
    end
  end

  before do
    ActiveJob::Base.logger = Logger.new('/dev/null')
  end

  describe '.perform_later' do
    subject { job_class.perform_later(arg) }

    let(:arg) { { message: 'hello' } }

    context 'when doesnt set delay' do
      before do
        expect_any_instance_of(job_class).to receive(:perform)
        expect(KubeQueue.client).to receive(:create_job).and_call_original
      end

      it { expect { subject }.not_to raise_error }
    end

    context 'when set delay' do
      subject { job_class.set(wait: 600).perform_later }

      before do
        expect_any_instance_of(job_class).to receive(:perform)
        expect(KubeQueue.client).to receive(:create_cron_job).and_call_original
      end

      it { expect { subject }.not_to raise_error }
    end
  end

  describe '.perform_now' do
    subject { job_class.perform_now(arg) }

    before { expect_any_instance_of(job_class).to receive(:perform).with(arg) }

    let(:arg) { { message: 'hello' } }

    it { expect { subject }.not_to raise_error }
  end
end
