# frozen_string_literal: true

module RSpec
  module FileSystem
    module Options
      # target: <expected>
      class SymlinkTarget
        def self.key = :target

        def self.description(expected)
          RSpec::FileSystem.matcher?(expected) ? expected.description : expected.inspect
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(String) ||
                    RSpec::FileSystem.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher or a String, but was #{expected.inspect}"
        end

        # Populates failure_messages if expected value does not match actual value
        # @param path [String] the path of the entry to check
        # @param expected [Object] the expected value
        # @param failure_messages [Array<String>] the array to populate with failure messages
        # @return [Void]
        #
        def self.match(path, expected, failure_messages)
          actual = File.readlink(path)

          case expected
          when String then match_string(actual, expected, failure_messages)
          else             match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_string(actual, expected, failure_messages)
          return if expected == actual

          failure_messages << "expected #{key} to be #{expected.inspect}, but was #{actual.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected #{key} to #{expected.description}, but was #{actual.inspect}"
        end
      end
    end
  end
end
