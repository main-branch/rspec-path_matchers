# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # mtime: <expected>
      class SymlinkMtime < FileStatBase
        def self.key = :mtime
        def self.stat_attribute = :mtime
        def self.valid_expected_types = [Time, DateTime]
        def self.normalize_expected_literal(expected) = expected.to_time
        def self.stat_source_method = :lstat
      end
    end
  end
end
