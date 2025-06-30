# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # target_type: <expected>
      #
      # Checks the type of the entry a symlink points to (e.g., 'file', 'directory').
      #
      class SymlinkTargetType < Base
        def self.key = :target_type
        def self.valid_expected_types = [String, Symbol]
        def self.normalize_expected_literal(expected) = expected.to_s

        # Overrides the base match method to gracefully handle dangling symlinks
        #
        # If `File.ftype` fails because the target doesn't exist, it adds a
        # descriptive failure instead of crashing.
        #
        def self.match(path, expected, failures)
          super
        rescue Errno::ENOENT => e
          message = "expected the symlink target to exist, but got error: #{e.message}"
          add_failure(message, failures)
          nil
        end

        def self.fetch_actual(path, _failures)
          File.ftype(File.expand_path(File.readlink(path), File.dirname(path)))
        end
      end
    end
  end
end
