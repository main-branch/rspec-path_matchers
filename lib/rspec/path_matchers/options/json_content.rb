# frozen_string_literal: true

require 'json'

module RSpec
  module PathMatchers
    module Options
      # json_content: <expected>
      class JsonContent
        def self.key = :json_content

        def self.description(expected)
          return 'be json content' if expected == true

          expected.description
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected == true ||
                    RSpec::PathMatchers.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher or true, but was #{expected.inspect}"
        end

        # Returns nil if the path matches the expected content
        # @param path [String] the path of the entry to check
        # @return [String, nil]
        #
        def self.match(path, expected, failure_messages)
          actual = JSON.parse(File.read(path))

          return if expected == true

          failure_messages << "expected JSON content to #{expected.description}" unless expected.matches?(actual)
        rescue JSON::ParserError => e
          failure_messages << "expected valid JSON content, but got error: #{e.message}"
        end
      end
    end
  end
end
