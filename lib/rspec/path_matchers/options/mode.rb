# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # mode: <expected>
      class Mode < FileStatBase
        def self.key = :mode
        def self.stat_attribute = :mode
        def self.valid_expected_types = [String]
        def self.fetch_actual(path, _failure_messages) = File.stat(path).mode.to_s(8)[-4..]
      end
    end
  end
end
