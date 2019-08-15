require 'spec_helper'

RSpec.describe KubeQueue do
  describe '.fetch_worker' do
    subject { KubeQueue.fetch_worker('TestWorker') }

    let!(:worker) do
      Class.new do
        def self.name
          'TestWorker'
        end

        include KubeQueue::Worker
      end
    end

    after { KubeQueue.worker_registry.clear }

    it { is_expected.to eq worker }
  end
end
