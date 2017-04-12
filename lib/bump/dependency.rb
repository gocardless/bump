# frozen_string_literal: true
require "gems"
require "bump/github"
require "bump/dependency_source_code_finders/ruby"
require "bump/dependency_source_code_finders/node"
require "bump/dependency_source_code_finders/python"

module Bump
  class Dependency
    attr_reader :name, :version, :previous_version, :language

    CHANGELOG_NAMES = %w(changelog history news changes).freeze
    TAG_PREFIX      = /^v/

    def initialize(name:, version:, previous_version: nil, language: nil)
      @name = name
      @version = version
      @previous_version = previous_version
      @language = language
    end

    def github_repo
      return unless language
      return @github_repo if @github_repo_lookup_attempted
      look_up_github_repo
    end

    def github_repo_url
      return unless github_repo
      Github.client.web_endpoint + github_repo
    end

    def github_compare_url
      return unless github_repo

      @tags ||= look_up_repo_tags

      if @tags.include?(previous_version) && @tags.include?(version)
        "#{github_repo_url}/compare/v#{previous_version}...v#{version}"
      elsif @tags.include?(version)
        "#{github_repo_url}/commits/v#{version}"
      else
        "#{github_repo_url}/commits"
      end
    end

    def changelog_url
      return unless github_repo
      return @changelog_url if @changelog_url_lookup_attempted

      look_up_changelog_url
    end

    def to_h
      {
        "name" => name,
        "version" => version,
        "previous_version" => previous_version,
        "language" => language
      }
    end

    private

    def look_up_github_repo
      @github_repo_lookup_attempted = true
      @github_repo = source_code_finder.github_repo
    end

    def look_up_changelog_url
      @changelog_url_lookup_attempted = true

      files = Github.client.contents(github_repo)
      file = files.find { |f| CHANGELOG_NAMES.any? { |w| f.name =~ /#{w}/i } }

      @changelog_url = file.nil? ? nil : file.html_url
    rescue Octokit::NotFound
      @changelog_url = nil
    end

    def look_up_repo_tags
      Github.client.tags(github_repo).map do |tag|
        tag["name"].to_s.gsub(TAG_PREFIX, "")
      end
    rescue Octokit::NotFound
      []
    end

    def source_code_finder
      @source_code_finder ||=
        begin
          finder_class =
            case language
            when "ruby" then DependencySourceCodeFinders::Ruby
            when "node" then DependencySourceCodeFinders::Node
            when "python" then DependencySourceCodeFinders::Python
            else raise "Invalid language #{language}"
            end

          finder_class.new(dependency_name: name)
        end
    end
  end
end
