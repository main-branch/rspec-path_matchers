# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # Inherits all logic from FileStatOption
      class Mtime < FileStatBase
        def self.key = :mtime
        def self.stat_attribute = :mtime
        def self.valid_expected_types = [Time, DateTime]
        def self.normalize_expected_literal(expected) = expected.to_time
      end
    end
  end
end
