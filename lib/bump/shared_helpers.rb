# frozen_string_literal: true
require "tmpdir"

module Bump
  module SharedHelpers
    BUMP_TMP_FILE_PREFIX = "bump_"
    BUMP_TMP_DIR_PATH = "tmp"

    class ChildProcessFailed < StandardError
      attr_reader :error_class, :error_message

      def initialize(error_class:, error_message:)
        @error_class = error_class
        @error_message = error_message

        msg = "Child process raised #{error_class} with message: "\
              "#{error_message}"
        super(msg)
      end
    end

    def self.in_a_temporary_directory
      Dir.mkdir(BUMP_TMP_DIR_PATH) unless Dir.exist?(BUMP_TMP_DIR_PATH)
      Dir.mktmpdir(BUMP_TMP_FILE_PREFIX, BUMP_TMP_DIR_PATH) do |dir|
        yield dir
      end
    end

    def self.in_a_forked_process
      read, write = IO.pipe

      pid = fork do
        begin
          read.close
          result = yield
        rescue => error
          result = { _error_details: { error_class: error.class.to_s,
                                       error_message: error.message } }
        ensure
          Marshal.dump(result, write)
          exit!(0)
        end
      end

      write.close
      result = read.read
      Process.wait(pid)
      result = Marshal.load(result)

      return result unless result.is_a?(Hash) && result[:_error_details]
      raise ChildProcessFailed, result[:_error_details]
    end
  end
end
