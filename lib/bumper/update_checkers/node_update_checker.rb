require "json"
require "net/http"

module UpdateCheckers
  class NodeUpdateChecker
    attr_reader :dependency

    def initialize(dependency)
      @dependency = dependency
    end

    def needs_update?
      Gem::Version.new(latest_version) > Gem::Version.new(dependency.version)
    end

    def latest_version
      url = URI("http://registry.npmjs.org/#{dependency.name}")
      @latest_version ||=
        JSON.parse(Net::HTTP.get(url))["dist-tags"]["latest"]
    end
  end
end
