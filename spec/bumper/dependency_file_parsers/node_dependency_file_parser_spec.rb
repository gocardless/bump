require "spec_helper"
require "bumper/dependency_file"
require "bumper/dependency_file_parsers/node_dependency_file_parser"

RSpec.describe DependencyFileParsers::NodeDependencyFileParser do
  let(:files) { [package_json] }
  let(:package_json) do
    DependencyFile.new(name: "package.json", content: package_json_body )
  end
  let(:package_json_body) { fixture("package.json") }

  let(:parser) do
    DependencyFileParsers::NodeDependencyFileParser.new(dependency_files: files)
  end

  describe "parse" do
    subject(:dependencies) { parser.parse }
    its(:length) { is_expected.to eq(4) }

    context "with development dependencies" do
      describe "the first dependency" do
        subject { dependencies.first }

        it { is_expected.to be_a(Dependency) }
        its(:name) { is_expected.to eq("immutable") }
        its(:version) { is_expected.to eq("1.1.0") }
      end

      describe "the last dependency" do
        subject { dependencies.last }

        it { is_expected.to be_a(Dependency) }
        its(:name) { is_expected.to eq("ansi-regex") }
        its(:version) { is_expected.to eq("2.0.0") }
      end
    end

    context "with no development dependencies" do
      let(:package_json_body) { fixture("package_json_samples", "no_dev_dependencies") }
      describe "the first dependency" do
        subject { dependencies.first }

        it { is_expected.to be_a(Dependency) }
        its(:name) { is_expected.to eq("immutable") }
        its(:version) { is_expected.to eq("1.1.0") }
      end

      describe "the last dependency" do
        subject { dependencies.last }

        it { is_expected.to be_a(Dependency) }
        its(:name) { is_expected.to eq("lodash") }
        its(:version) { is_expected.to eq("1.3.1") }
      end
    end
  end
end
