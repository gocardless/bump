require "gemnasium/parser"
require "bumper/dependency"

module DependencyFileParsers
  class RubyDependencyFileParser
    def initialize(dependency_files)
      @gemfile = dependency_files.find { |f| f.name == "Gemfile" }
      raise "No Gemfile!" unless @gemfile
    end

    def parse
      parser.dependencies.map do |dependency|
        version = dependency.requirement.to_s.match(/[\d\.]+/)[0]
        Dependency.new(name: dependency.name, version: version)
      end
    end

    private

    def parser
      Gemnasium::Parser.gemfile(@gemfile.content)
    end
  end
end