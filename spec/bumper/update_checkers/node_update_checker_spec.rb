require "spec_helper"
require "bumper/dependency"
require "bumper/update_checkers/node_update_checker"

RSpec.describe UpdateCheckers::NodeUpdateChecker do
  before do
    stub_request(:get, npm_registry_url).
      to_return(status: 200, body: fixture("npm", "registry_lodash"))
  end

  let(:npm_registry_url) { "http://registry.npmjs.org/#{dependency_name}" }

  let(:checker) { UpdateCheckers::NodeUpdateChecker.new(dependency) }
  let(:dependency_name) { "lodash" }
  let(:dependency_version) { "1.3.1" }
  let(:dependency_language) { "node" }
  let(:dependency) do
    Dependency.new(
      name: dependency_name,
      version: dependency_version,
      language: dependency_language,
    )
  end

  describe "#needs_update?" do
    subject { checker.needs_update? }

    context "given an up-to-date dependency" do
      let(:dependency_version) { "3.10.1" }
      it { is_expected.to be_falsey }
    end

    context "given an outdated dependency" do
      it { is_expected.to be_truthy }
    end
  end

  describe "#latest_version" do
    subject { checker.latest_version }
    it { is_expected.to eq("3.10.1") }
  end
end
