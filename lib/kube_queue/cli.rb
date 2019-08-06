require 'logger'
require 'json'
require 'optparse'
require 'kube_queue/runner'

module KubeQueue
  class CLI
    attr_reader :argv

    def initialize(argv = ARGV)
      parse_options(argv)

      @argv = argv
    end

    def run
      load_files!

      runner = Runner.new(job_name)

      runner.run(payload)
    end

    private

    def job_name
      argv[0]
    end

    def payload
      payload = ENV['KUBE_QUEUE_MESSAGE_PAYLOAD']

      return payload if payload

      raise 'Payload is missing. Please set payload to KUBE_QUEUE_MESSAGE_PAYLOAD environment variable'
    end

    def load_files!
      require options[:require] if options[:require]
    end

    def options
      @options ||= {}
    end

    def parse_options(argv)
      parser = OptionParser.new do |o|
        o.on '-r', '--require [PATH|DIR]', 'Location of Rails application with workers or file to require' do |arg|
          options[:require] = arg
        end
      end

      parser.parse!(argv)
    end
  end
end
