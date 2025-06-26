# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # birthtime: <expected>
      class Birthtime < FileStatBase
        def self.key = :birthtime
        def self.stat_attribute = :birthtime
        def self.valid_expected_types = [Time, DateTime]
        def self.normalize_expected_literal(expected) = expected.to_time
      end
    end
  end
end
