# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Options
      # group: <expected>
      class Group
        def self.key = :group

        def self.description(expected)
          RSpec::PathMatchers.matcher?(expected) ? expected.description : expected.inspect
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(String) ||
                    RSpec::PathMatchers.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher or a String, but was #{expected.inspect}"
        end

        # Returns nil if the path is owned by the expected owner
        # @param path [String] the path of the entry to check
        # @return [String, nil]
        #
        def self.match(path, expected, failure_messages)
          return if unsupported_platform?

          actual = Etc.getgrgid(File.stat(path).gid).name

          case expected
          when String then match_string(actual, expected, failure_messages)
          else             match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.unsupported_platform?
          return false if Etc.respond_to?(:getgrgid)

          # If the platform doesn't support Group checks, warn the user and skip the check
          message = 'WARNING: Group expectations are not supported on this platform and will be skipped.'
          RSpec.configuration.reporter.message(message)
          true
        end

        private_class_method def self.match_string(actual, expected, failure_messages)
          return if expected == actual

          failure_messages << "expected group to be #{expected.inspect}, but was #{actual.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected group to #{expected.description}, but was #{actual.inspect}"
        end
      end
    end
  end
end
