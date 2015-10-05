require "spec_helper"
require "tmpdir"
require "bumper/dependency_file"
require "bumper/dependency"
require "bumper/dependency_file_updaters/node_dependency_file_updater"

RSpec.describe DependencyFileUpdaters::NodeDependencyFileUpdater do
  let(:updater) do
    described_class.new(
      dependency_files: [package_json, shrinkwrap],
      dependency: dependency
    )
  end
  let(:package_json) { DependencyFile.new(content: package_json_body, name: "package.json") }
  let(:package_json_body) { fixture("package.json") }
  let(:shrinkwrap) do
    DependencyFile.new(
      content: fixture("npm-shrinkwrap.json"),
      name: "npm-shrinkwrap.json"
    )
  end

  let(:dependency) { Dependency.new(name: "lodash", version: "3.10.1", language: "node") }
  let(:tmp_path) { described_class::BUMP_TMP_DIR_PATH }

  before { Dir.mkdir(tmp_path) unless Dir.exist?(tmp_path) }

  describe "#updated_dependency_files" do
    subject(:updated_files) { updater.updated_dependency_files }

    specify { expect { updated_files }.to_not change { Dir.entries(tmp_path) } }
    specify { updated_files.each { |file| expect(file).to be_a(DependencyFile) } }
    its(:length) { is_expected.to eq(2) }

    context "when the old pacakge.json specifies the version" do
      describe "the updated package.json" do
        subject(:file) { updated_files.find { |file| file.name == "package.json" } }
        its(:content) { is_expected.to include "lodash" }
        its(:content) { is_expected.to include "3.10.1" }
      end

      describe "the updated shrinkwrap" do
        subject(:file) { updated_files.find { |f| f.name == "npm-shrinkwrap.json" } }
        its(:content) { is_expected.to include "\"lodash\"" }
        its(:content) { is_expected.to include "\"version\": \"3.10.1\"" }
      end
    end

    context "without pacakge.json" do
      subject { -> { updater } }
      let(:updater) do
        described_class.new(dependency_files: [shrinkwrap], dependency: dependency)
      end

      it { is_expected.to raise_error(/No package.json!/) }
    end
  end
end
