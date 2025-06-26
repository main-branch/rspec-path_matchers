# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # ctime: <expected>
      class Ctime < FileStatBase
        def self.key = :ctime
        def self.stat_attribute = :ctime
        def self.valid_expected_types = [Time, DateTime]
        def self.normalize_expected_literal(expected) = expected.to_time
      end
    end
  end
end
