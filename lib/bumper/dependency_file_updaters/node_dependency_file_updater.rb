require "gemnasium/parser"
require "bumper/dependency_file"
require "tmpdir"
require "json"

module DependencyFileUpdaters
  class NodeDependencyFileUpdater
    attr_reader :package_json, :shrinkwrap, :dependency

    BUMP_TMP_FILE_PREFIX = "bump_".freeze
    BUMP_TMP_DIR_PATH = "tmp".freeze
    PACKAGE_JSON_NAME = "package.json".freeze
    SHRINKWRAP_NAME = "npm-shrinkwrap.json".freeze

    def initialize(dependency_files:, dependency:)
      @package_json = dependency_files.find { |f| f.name == PACKAGE_JSON_NAME }
      @shrinkwrap = dependency_files.find { |f| f.name == SHRINKWRAP_NAME }
      validate_necessary_file_is_present!

      @dependency = dependency
    end

    def updated_dependency_files
      return @updated_dependency_files if @updated_dependency_files

      @updated_dependency_files = [
        DependencyFile.new(
          name: PACKAGE_JSON_NAME,
          content: updated_package_json_content
        ),
        DependencyFile.new(
          name: SHRINKWRAP_NAME,
          content: updated_shrinkwrap_content
        )
      ]
    end

    private

    def validate_necessary_file_is_present!
      raise "No package.json!" unless package_json
    end

    def updated_package_json_content
      return @updated_package_json_content if @updated_package_json_content

      parsed_content = JSON.parse(@package_json.content)

      if parsed_content["dependencies"][dependency.name] != nil
        parsed_content["dependencies"][dependency.name] = dependency.version
      end

      if parsed_content["devDependencies"][dependency.name] != nil
        parsed_content["devDependencies"][dependency.name]  = dependency.version
      end

      @updated_package_json_content = JSON.generate(parsed_content)
    end

    def updated_shrinkwrap_content
      return @updated_shrinkwrap_content if @updated_shrinkwrap_content

      in_a_temporary_directory do |dir|
        File.write(File.join(dir, PACKAGE_JSON_NAME), updated_package_json_content)
        # FIXME: needs to deal with shrinkwrap
        # File.write(File.join(dir, SHRINKWRAP_NAME), shrinkwrap.content) unless shrinkwrap.nil?
        system "cd #{dir} && npm i --silent > tmp.log && npm shrinkwrap --silent  > tmp.log"

        @updated_shrinkwrap_content =
          File.read(File.join(dir, SHRINKWRAP_NAME))
      end

      @updated_shrinkwrap_content
    end

    def in_a_temporary_directory
      Dir.mkdir(BUMP_TMP_DIR_PATH) unless Dir.exist?(BUMP_TMP_DIR_PATH)
      Dir.mktmpdir(BUMP_TMP_FILE_PREFIX, BUMP_TMP_DIR_PATH) do |dir|
        yield dir
      end
    end
  end
end
