# frozen_string_literal: true

require "sidekiq"
require "octokit"
require "./app/boot"
require "bump/dependency"
require "bump/dependency_file"
require "bump/repo"
require "bump/update_checkers"
require "bump/file_updaters"
require "bump/pull_request_creator"

$stdout.sync = true

module Workers
  class DependencyUpdater
    include Sidekiq::Worker

    sidekiq_options queue: "bump-dependencies_to_update", retry: 4

    sidekiq_retry_in { |count| [60, 300, 3_600, 36_000][count] }

    def perform(body)
      @repo = Bump::Repo.new(**symbolize_hash_keys(body["repo"]))
      @dependency = Bump::Dependency.
                    new(**symbolize_hash_keys(body["dependency"]))
      @dependency_files = body["dependency_files"].map do |file|
        Bump::DependencyFile.new(**symbolize_hash_keys(file))
      end

      updated_dependency, updated_dependency_files = update_dependency!

      return if updated_dependency.nil?

      Bump::PullRequestCreator.new(
        repo: repo.name,
        base_commit: repo.commit,
        dependency: updated_dependency,
        files: updated_dependency_files,
        github_client: github_client
      ).create
    rescue Bump::DependencyFileNotResolvable
      nil
    rescue StandardError => error
      Raven.capture_exception(error, extra: { body: body })
      raise
    end

    private

    attr_reader :dependency, :dependency_files, :repo

    def update_dependency!
      checker = update_checker.new(
        dependency: dependency,
        dependency_files: dependency_files,
        github_access_token: bump_github_token
      )

      return unless checker.needs_update?

      updated_dependency = checker.updated_dependency

      updated_dependency_files = file_updater.new(
        dependency: updated_dependency,
        dependency_files: dependency_files,
        github_access_token: bump_github_token
      ).updated_dependency_files

      [updated_dependency, updated_dependency_files]
    end

    def update_checker
      Bump::UpdateCheckers.for_package_manager(dependency.package_manager)
    end

    def file_updater
      Bump::FileUpdaters.for_package_manager(dependency.package_manager)
    end

    def bump_github_token
      Prius.get(:bump_github_token)
    end

    def github_client
      Octokit::Client.new(access_token: bump_github_token)
    end

    def symbolize_hash_keys(hash)
      hash.each_with_object({}) do |(key, value), transformed_hash|
        transformed_key = key.respond_to?(:to_sym) ? key.to_sym : key
        transformed_hash[transformed_key] = value
      end
    end
  end
end
