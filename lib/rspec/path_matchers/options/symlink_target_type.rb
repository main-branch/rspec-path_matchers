# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # target_type: <expected>
      class SymlinkTargetType < Base
        def self.key = :target_type
        def self.valid_expected_types = [String, Symbol]
        def self.normalize_expected_literal(expected) = expected.to_s

        def self.match(path, expected, failure_messages)
          super
        rescue Errno::ENOENT => e
          failure_messages << "expected the symlink target to exist, but got error: #{e.message}"
          nil
        end

        def self.fetch_actual(path, _failure_messages)
          File.ftype(File.expand_path(File.readlink(path), File.dirname(path)))
        end
      end
    end
  end
end
