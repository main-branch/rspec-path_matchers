# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Options
      # target_exist: <expected>
      class SymlinkTargetExist
        def self.key = :target_exist?

        def self.description(expected)
          RSpec::PathMatchers.matcher?(expected) ? expected.description : expected.to_s
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(TrueClass) || expected.is_a?(FalseClass) ||
                    RSpec::PathMatchers.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher, true, or false but was #{expected.inspect}"
        end

        # Populates failure_messages if expected value does not match actual value
        # @param path [String] the path of the entry to check
        # @param expected [Object] the expected value
        # @param failure_messages [Array<String>] the array to populate with failure messages
        # @return [Void]
        #
        def self.match(path, expected, failure_messages)
          actual = File.exist?(File.expand_path(File.readlink(path), File.dirname(path)))

          case expected
          when true, false then match_boolean(actual, expected, failure_messages)
          else                  match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_boolean(actual, expected, failure_messages)
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
