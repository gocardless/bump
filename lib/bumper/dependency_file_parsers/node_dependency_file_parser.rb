require "bumper/dependency"
require "json"

module DependencyFileParsers
  class NodeDependencyFileParser
    def initialize(dependency_files:)
      @package_json = dependency_files.find { |f| f.name == "package.json" }
      raise "No package.json!" unless @package_json
    end

    def parse
      parsed_content = parser

      dependencies_hash = parsed_content["dependencies"] || {}
      dependencies_hash.merge!(parsed_content["devDependencies"] || {})

      dependencies_hash.map do |name, version|
        Dependency.new(name: name, version: version, language: "node")
      end
    end

    private

    def parser
      JSON.parse(@package_json.content)
    end
  end
end
