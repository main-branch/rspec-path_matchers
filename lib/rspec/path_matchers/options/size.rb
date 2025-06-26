# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # size: <expected>
      class Size < FileStatBase
        def self.key = :size
        def self.stat_attribute = :size
        def self.valid_expected_types = [Integer]
      end
    end
  end
end
