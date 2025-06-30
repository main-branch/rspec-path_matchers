# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # target: <expected>
      class SymlinkTarget < Base
        def self.key = :target
        def self.valid_expected_types = [String]
        def self.normalize_expected_literal(expected) = expected.to_s
        def self.fetch_actual(path, _failures) = File.readlink(path)
      end
    end
  end
end
