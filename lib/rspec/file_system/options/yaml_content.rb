# frozen_string_literal: true

require 'yaml'

module RSpec
  module FileSystem
    module Options
      # yaml_content: <expected>
      class YamlContent
        def self.key = :yaml_content

        def self.description(expected)
          return 'be yaml content' if expected == true

          expected.description
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected == true ||
                    RSpec::FileSystem.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher or true, but was #{expected.inspect}"
        end

        # Returns nil if the path matches the expected content
        # @param path [String] the path of the entry to check
        # @return [String, nil]
        #
        def self.match(path, expected, failure_messages)
          require 'yaml'
          actual = YAML.safe_load_file(path)

          return if expected == true

          failure_messages << "expected YAML content to #{expected.description}" unless expected.matches?(actual)
        rescue Psych::SyntaxError => e
          failure_messages << "expected valid YAML content, but got error: #{e.message}"
        end
      end
    end
  end
end
