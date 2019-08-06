module KubeQueue
  class Configuration
    def configure
      yield self
    end
  end
end
