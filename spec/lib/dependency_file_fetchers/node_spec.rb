# frozen_string_literal: true
require "spec_helper"
require "bump/dependency_file_fetchers/node"

RSpec.describe Bump::DependencyFileFetchers::Node do
  let(:file_fetcher) { described_class.new(repo) }
  let(:repo) { "gocardless/bump" }

  describe "#files" do
    subject(:files) { file_fetcher.files }
    let(:url) { "https://api.github.com/repos/#{repo}/contents/" }
    before do
      stub_request(:get, url + "package.json").
        to_return(status: 200,
                  body: fixture("github", "package_json_content.json"),
                  headers: { "content-type" => "application/json" })
      stub_request(:get, url + "yarn.lock").
        to_return(status: 200,
                  body: fixture("github", "yarn_lock_content.json"),
                  headers: { "content-type" => "application/json" })
    end

    its(:length) { is_expected.to eq(2) }

    describe "the package.json" do
      subject { files.find { |file| file.name == "package.json" } }

      it { is_expected.to be_a(Bump::DependencyFile) }
      its(:content) { is_expected.to include("lodash") }
    end

    describe "the yarn.lock" do
      subject { files.find { |file| file.name == "yarn.lock" } }

      it { is_expected.to be_a(Bump::DependencyFile) }
      its(:content) { is_expected.to include("lodash") }
    end
  end
end
