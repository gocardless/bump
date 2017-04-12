# frozen_string_literal: true
require "spec_helper"
require "bump/dependency"
require "bump/dependency_file"
require "bump/pull_request_creator"

RSpec.describe Bump::PullRequestCreator do
  subject(:creator) do
    Bump::PullRequestCreator.new(repo: repo,
                                 base_commit: base_commit,
                                 dependency: dependency,
                                 files: files)
  end

  let(:dependency) do
    Bump::Dependency.new(name: "business",
                         version: "1.5.0",
                         previous_version: "1.4.0",
                         language: "ruby")
  end
  let(:repo) { "gocardless/bump" }
  let(:files) { [gemfile, gemfile_lock] }
  let(:base_commit) { "basecommitsha" }

  let(:gemfile) do
    Bump::DependencyFile.new(name: "Gemfile", content: fixture("Gemfile"))
  end
  let(:gemfile_lock) do
    Bump::DependencyFile.new(
      name: "Gemfile.lock",
      content: fixture("Gemfile.lock")
    )
  end

  let(:json_header) { { "Content-Type" => "application/json" } }
  let(:watched_repo_url) { "https://api.github.com/repos/#{repo}" }
  let(:business_repo_url) { "https://api.github.com/repos/gocardless/business" }
  let(:branch_name) { "bump_business_to_1.5.0" }

  before do
    stub_request(:get, watched_repo_url).
      to_return(status: 200,
                body: fixture("github", "bump_repo.json"),
                headers: json_header)
    stub_request(:get, "#{watched_repo_url}/git/refs/heads/#{branch_name}").
      to_return(status: 404,
                body: fixture("github", "not_found.json"),
                headers: json_header)
    stub_request(:post, "#{watched_repo_url}/git/trees").
      to_return(status: 200,
                body: fixture("github", "create_tree.json"),
                headers: json_header)
    stub_request(:post, "#{watched_repo_url}/git/commits").
      to_return(status: 200,
                body: fixture("github", "create_commit.json"),
                headers: json_header)
    stub_request(:post, "#{watched_repo_url}/git/refs").
      to_return(status: 200,
                body: fixture("github", "create_ref.json"),
                headers: json_header)
    stub_request(:post, "#{watched_repo_url}/pulls").
      to_return(status: 200,
                body: fixture("github", "create_pr.json"),
                headers: json_header)

    stub_request(:get, business_repo_url).
      to_return(status: 200,
                body: fixture("github", "business_repo.json"),
                headers: json_header)
    stub_request(:get, "#{business_repo_url}/contents/").
      to_return(status: 200,
                body: fixture("github", "business_files.json"),
                headers: json_header)
    stub_request(:get, "#{business_repo_url}/tags").
      to_return(status: 200,
                body: fixture("github", "business_tags.json"),
                headers: json_header)
    stub_request(:get, "https://rubygems.org/api/v1/gems/business.json").
      to_return(status: 200, body: fixture("rubygems_response.json"))
  end

  describe "#create" do
    it "pushes a commit to GitHub" do
      creator.create

      expect(WebMock).
        to have_requested(:post, "#{watched_repo_url}/git/trees").
        with(body: {
               base_tree: "basecommitsha",
               tree: [
                 {
                   path: "Gemfile",
                   mode: "100644",
                   type: "blob",
                   content: fixture("Gemfile")
                 },
                 {
                   path: "Gemfile.lock",
                   mode: "100644",
                   type: "blob",
                   content: fixture("Gemfile.lock")
                 }
               ]
             })

      expect(WebMock).
        to have_requested(:post, "#{watched_repo_url}/git/commits")
    end

    it "creates a branch for that commit" do
      creator.create

      expect(WebMock).
        to have_requested(:post, "#{watched_repo_url}/git/refs").
        with(body: {
               ref: "refs/heads/bump_business_to_1.5.0",
               sha: "7638417db6d59f3c431d3e1f261cc637155684cd"
             })
    end

    it "creates a PR with the right details" do
      creator.create

      repo_url = "https://api.github.com/repos/gocardless/bump"
      expect(WebMock).
        to have_requested(:post, "#{repo_url}/pulls").
        with(
          body: {
            base: "master",
            head: "bump_business_to_1.5.0",
            title: "Bump business to 1.5.0",
            body: "Bumps [business](#{dependency.github_repo_url}) to 1.5.0."\
                  "\n- [Changelog](#{dependency.changelog_url})"\
                  "\n- [Changes since 1.4.0](#{dependency.github_repo_url}/"\
                    "compare/v1.4.0...v1.5.0)"
          }
        )
    end

    context "when a branch for this update already exists" do
      before do
        stub_request(:get, "#{watched_repo_url}/git/refs/heads/#{branch_name}").
          to_return(status: 200,
                    body: fixture("github", "check_ref.json"),
                    headers: json_header)
      end

      specify { expect { creator.create }.to_not raise_error }

      it "doesn't push changes to the branch" do
        creator.create

        expect(WebMock).
          to_not have_requested(:post, "#{watched_repo_url}/git/trees")
      end

      it "doesn't try to re-create the PR" do
        creator.create
        expect(WebMock).
          to_not have_requested(:post, "#{watched_repo_url}/pulls")
      end
    end
  end
end
