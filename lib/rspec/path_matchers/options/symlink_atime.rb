# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # atime: <expected>
      class SymlinkAtime < FileStatBase
        def self.key = :atime
        def self.stat_attribute = :atime
        def self.valid_expected_types = [Time, DateTime]
        def self.normalize_expected_literal(expected) = expected.to_time
        def self.stat_source_method = :lstat
      end
    end
  end
end
