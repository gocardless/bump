require "sidekiq"
require "bumper/workers"
require "bumper/dependency"
require "bumper/dependency_file"
require "bumper/update_checkers/ruby_update_checker"

module Workers
  class UpdateChecker
    include Sidekiq::Worker

    sidekiq_options queue: "dependencies_to_check"

    def perform(_sqs_message, body)
      dependency = Dependency.new(name: body["dependency"]["name"],
                                  version: body["dependency"]["version"])
      dependency_files = body["dependency_files"].map do |file|
        DependencyFile.new(name: file["name"], content: file["content"])
      end

      update_checker = update_checker_for(body["repo"]["language"]).new(
        dependency: dependency,
        dependency_files: dependency_files
      )
      return unless update_checker.needs_update?

      update_dependency(body["repo"],
                        body["dependency_files"],
                        Dependency.new(name: dependency.name,
                                       version: update_checker.latest_version))
    rescue => error
      Raven.capture_exception(error)
      raise
    end

    private

    def update_dependency(repo, dependency_files, updated_dependency)
      Workers::DependencyFileUpdater.perform_async(
        "repo" => repo,
        "dependency_files" => dependency_files,
        "updated_dependency" => {
          "name" => updated_dependency.name,
          "version" => updated_dependency.version
        }
      )
    end

    def update_checker_for(language)
      case language
      when "ruby" then UpdateCheckers::RubyUpdateChecker
      else raise "Invalid language #{language}"
      end
    end
  end
end
