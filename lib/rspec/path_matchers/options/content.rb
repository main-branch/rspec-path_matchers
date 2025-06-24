# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Options
      # content: <expected>
      class Content
        def self.key = :content

        def self.description(expected)
          RSpec::PathMatchers.matcher?(expected) ? expected.description : expected.inspect
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(String) ||
                    expected.is_a?(Regexp) ||
                    RSpec::PathMatchers.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a String, Regexp, or Matcher, but was #{expected.inspect}"
        end

        # Returns nil if the path matches the expected content
        # @param path [String] the path of the entry to check
        # @return [String, nil]
        #
        def self.match(path, expected, failure_messages)
          actual = File.read(path)
          case expected
          when String then match_string(actual, expected, failure_messages)
          when Regexp then match_regexp(actual, expected, failure_messages)
          else             match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_string(actual, expected, failure_messages)
          return if expected == actual

          failure_messages << "expected content to be #{expected.inspect}"
        end

        private_class_method def self.match_regexp(actual, expected, failure_messages)
          return if expected.match?(actual)

          failure_messages << "expected content to match #{expected.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected content to #{expected.description}"
        end
      end
    end
  end
end
