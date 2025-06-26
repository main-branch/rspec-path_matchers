# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # atime: <expected>
      class Atime < FileStatBase
        def self.key = :atime
        def self.stat_attribute = :atime
        def self.valid_expected_types = [Time, DateTime]
        def self.normalize_expected_literal(expected) = expected.to_time
      end
    end
  end
end
