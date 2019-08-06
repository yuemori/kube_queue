FROM ruby

WORKDIR /app

RUN apt-get update -y && apt-get install git --no-install-recommends && rm -r /var/cache/apt /var/lib/apt/lists

RUN gem install bundler:2.0.2
COPY docker/Gemfile Gemfile
COPY Gemfile kube_queue.gemspec .git  /vendor/kube_queue/
COPY exe/kube_queue /vendor/kube_queue/exe/kube_queue
COPY lib/kube_queue/version.rb /vendor/kube_queue/lib/kube_queue/version.rb
RUN bundle install -j4

COPY docker/test_worker.rb .
COPY . /vendor/kube_queue

CMD ["bundle", "exec", "kube_queue", "TestWorker", "-r", "./test_worker.rb"]
