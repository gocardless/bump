# frozen_string_literal: true
require "spec_helper"
require "bump/dependency"
require "bump/dependency_file"
require "bump/update_checkers/node"

RSpec.describe Bump::UpdateCheckers::Node do
  before do
    stub_request(:get, "http://registry.npmjs.org/etag").
      to_return(status: 200, body: fixture("npm_response.json"))
  end

  let(:checker) do
    described_class.new(dependency: dependency, dependency_files: [])
  end

  let(:dependency) { Bump::Dependency.new(name: "etag", version: "1.0.0") }

  describe "#needs_update?" do
    subject { checker.needs_update? }

    context "given an outdated dependency" do
      it { is_expected.to be_truthy }
    end

    context "given an up-to-date dependency" do
      let(:dependency) { Bump::Dependency.new(name: "etag", version: "1.7.0") }
      it { is_expected.to be_falsey }
    end

    context "for a scoped package name" do
      before do
        stub_request(:get, "http://registry.npmjs.org/@blep%2Fblep").
          to_return(status: 200, body: fixture("npm_response.json"))
      end
      let(:dependency) do
        Bump::Dependency.new(name: "@blep/blep", version: "1.0.0")
      end
      it { is_expected.to be_truthy }
    end
  end

  describe "#latest_version" do
    subject { checker.latest_version }
    it { is_expected.to eq("1.7.0") }
  end
end
