# frozen_string_literal: true

module RSpec
  module FileSystem
    module Options
      # mode: <expected>
      class Mode
        def self.key = :mode

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(String) ||
                    RSpec::FileSystem.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher or a String, but was #{expected.inspect}"
        end

        # Returns nil if the path matches the expected mode
        # @param path [String] the path of the entry to check
        # @return [String, nil]
        #
        def self.match(path, expected, failure_messages)
          actual = File.stat(path).mode.to_s(8)[-4..] # Get the last 4 characters of the octal mode
          case expected
          when String then match_string(actual, expected, failure_messages)
          else match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_string(actual, expected, failure_messages)
          return if expected == actual

          failure_messages << "expected mode to be #{expected.inspect}, but was #{actual.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected mode to #{expected.description}, but was #{actual.inspect}"
        end
      end
    end
  end
end
