require "sidekiq"
require "bumper/workers"
require "bumper/dependency_file"
require "bumper/dependency_file_parsers/ruby_dependency_file_parser"

module Workers
  class DependencyFileParser
    include Sidekiq::Worker

    sidekiq_options queue: "dependency_files_to_parse"

    def perform(_sqs_message, body)
      parser = parser_for(body["repo"]["language"])
      dependency_files = body["dependency_files"].map do |file|
        DependencyFile.new(name: file["name"], content: file["content"])
      end
      dependencies = parser.new(dependency_files: dependency_files).parse

      dependencies.each do |dependency|
        check_for_dependency_update(
          body["repo"],
          body["dependency_files"],
          dependency
        )
      end
    rescue => error
      Raven.capture_exception(error)
      raise
    end

    private

    def check_for_dependency_update(repo, dependency_files, dependency)
      Workers::UpdateChecker.perform_async(
        "repo" => repo,
        "dependency_files" => dependency_files,
        "dependency" => {
          "name" => dependency.name,
          "version" => dependency.version
        }
      )
    end

    def parser_for(language)
      case language
      when "ruby" then DependencyFileParsers::RubyDependencyFileParser
      else raise "Invalid language #{language}"
      end
    end
  end
end
