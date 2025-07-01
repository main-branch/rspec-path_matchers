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

        # Override to provide custom matching logic for regexp literals
        def self.literal_match?(actual, expected)
          expected.is_a?(Regexp) ? expected.match?(actual) : super
        end

        # Handles failures when a matcher is used (e.g., content: include('...'))
        def self.matcher_failure_message(actual, expected)
          actual_summary = actual.length > 100 ? 'did not' : "was #{actual.inspect}"
          "expected content to #{expected.description}, but it #{actual_summary}"
        end

        def self.literal_failure_message(actual, expected)
          verb = expected.is_a?(Regexp) ? 'match' : 'be'

          actual_summary =
            if actual.length > 100
              verb == 'match' ? 'did not' : 'was not'
            else
              "was #{actual.inspect}"
            end

          "expected content to #{verb} #{expected.inspect}, but it #{actual_summary}"
        end
      end
    end
  end
end
