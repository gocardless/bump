require "sidekiq"
require "bumper/workers"
require "bumper/dependency_file"
require "bumper/dependency_file_fetchers/ruby_dependency_file_fetcher"

module Workers
  class DependencyFileFetcher
    include Sidekiq::Worker

    sidekiq_options queue: "repos_to_fetch_files_for"

    def perform(_sqs_message, body)
      file_fetcher = file_fetcher_for(body["repo"]["language"])

      dependency_files =
        file_fetcher.new(body["repo"]["name"]).files.map do |file|
          { "name" => file.name, "content" => file.content }
        end

      Workers::DependencyFileParser.perform_async(
        "repo" => body["repo"],
        "dependency_files" => dependency_files
      )
    rescue => error
      Raven.capture_exception(error)
      raise
    end

    private

    def file_fetcher_for(language)
      case language
      when "ruby" then DependencyFileFetchers::RubyDependencyFileFetcher
      else raise "Invalid language #{language}"
      end
    end
  end
end
