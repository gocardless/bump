# frozen_string_literal: true

require "sidekiq"
require "./app/boot"
require "bump/dependency_file"
require "bump/dependency_file_fetchers"
require "bump/dependency_file_parsers"

$stdout.sync = true

module Workers
  class DependencyFileFetcher
    include Sidekiq::Worker

    sidekiq_options queue: "bump-repos_to_fetch_files_for", retry: 4

    sidekiq_retry_in { |count| [60, 300, 3_600, 36_000][count] }

    def perform(body)
      @body = body

      file_fetcher = file_fetcher_for(repo.language).new(
        repo: repo,
        github_client: github_client
      )

      parser = parser_for(repo.language)

      dependencies = parser.new(dependency_files: file_fetcher.files).parse

      dependencies.each do |dependency|
        Workers::DependencyUpdater.perform_async(
          "repo" => repo.to_h.merge("commit" => file_fetcher.commit),
          "dependency_files" => file_fetcher.files.map(&:to_h),
          "dependency" => dependency.to_h
        )
      end
    rescue => error
      Raven.capture_exception(error, extra: { body: body })
      raise
    end

    private

    def repo
      @repo ||= Bump::Repo.new(
        name: @body["repo"]["name"],
        language: @body["repo"]["language"],
        commit: nil
      )
    end

    def file_fetcher_for(language)
      Bump::DependencyFileFetchers.for_language(language)
    end

    def parser_for(language)
      Bump::DependencyFileParsers.for_language(language)
    end

    def github_client
      Octokit::Client.new(access_token: Prius.get(:bump_github_token))
    end
  end
end
