# frozen_string_literal: true
require "excon"
require "bump/dependency_source_code_finders/base"

module Bump
  module DependencySourceCodeFinders
    class Node < Base
      private

      def look_up_github_repo
        @github_repo_lookup_attempted = true

        npm_url = "http://registry.npmjs.org/#{dependency_name}"
        all_versions =
          JSON.parse(Excon.get(npm_url).body).fetch("versions", {}).values

        potential_source_urls =
          all_versions.map { |v| get_url(v.fetch("repository", {})) } +
          all_versions.map { |v| v["homepage"] } +
          all_versions.map { |v| get_url(v.fetch("bugs", {})) }

        potential_source_urls = potential_source_urls.compact

        source_url = potential_source_urls.find { |url| url =~ GITHUB_REGEX }

        @github_repo = source_url.match(GITHUB_REGEX)[:repo] if source_url
      end

      def get_url(details)
        case details
        when String then details
        when Hash then details.fetch("url", nil)
        end
      end
    end
  end
end
