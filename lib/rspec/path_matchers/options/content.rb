# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # content: <expected>
      class Content < Base
        def self.key = :content
        def self.fetch_actual(path, _failures) = File.read(path)
        def self.valid_expected_types = [String, Regexp]

        def self.literal_match?(actual, expected)
          return expected.match?(actual) if expected.is_a?(Regexp)

          super
        end

        def self.literal_failure_message(actual, expected)
          if expected.is_a?(Regexp)
            "expected content to match #{expected.inspect}, but got #{actual.inspect}"
          else
            super
          end
        end
      end
    end
  end
end
