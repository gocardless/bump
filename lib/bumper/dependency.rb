require "gems"
require "github"

class Dependency
  attr_reader :name, :version, :language

  CHANGELOG_NAMES = %w(changelog history)
  GITHUB_REGEX    = %r{github\.com/(?<repo>[^/]+/[^/]+)/?}
  SOURCE_KEYS     = %w(source_code_uri homepage_uri wiki_uri bug_tracker_uri
                       documentation_uri)

  def initialize(name:, version:, language:)
    @name = name
    @version = version
    @language = language
  end

  def github_repo
    return @github_repo if @github_repo_lookup_attempted
    look_up_github_repo
  end

  def github_repo_url
    return unless github_repo
    Github.client.web_endpoint + github_repo
  end

  def changelog_url
    return unless github_repo
    return @changelog_url if @changelog_url_lookup_attempted

    look_up_changelog_url
  end

  private

  def look_up_github_repo
    @github_repo_lookup_attempted = true
    case language
    when "ruby" then
      potential_source_urls =
        Gems.info(name).select { |key, _| SOURCE_KEYS.include?(key) }.values
      source_url = potential_source_urls.find { |url| url =~ GITHUB_REGEX }

      @github_repo = source_url.nil? ? nil : source_url.match(GITHUB_REGEX)[:repo]
    when "node" then UpdateCheckers::NodeUpdateChecker
      url = URI("http://registry.npmjs.org/#{dependency.name}")
      homepage = JSON.parse(Net::HTTP.get(url))["versions"].values.last["homepage"]
      @github_repo = homepage.include? "github.com" ? homepage.match(GITHUB_REGEX)[:repo] : nil
    else raise "Invalid language #{language}"
    end
  end

  def look_up_changelog_url
    @changelog_url_lookup_attempted = true

    files = Github.client.contents(github_repo)
    file = files.find { |f| CHANGELOG_NAMES.any? { |w| f.name =~ /#{w}/i } }

    @changelog_url = file.nil? ? nil : file.html_url
    rescue Octokit::NotFound
    @changelog_url = nil
  end
end
