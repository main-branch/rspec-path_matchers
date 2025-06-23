# frozen_string_literal: true

module RSpec
  module FileSystem
    module Options
      # birthtime: <expected>
      class SymlinkBirthtime
        def self.key = :birthtime

        def self.description(expected)
          RSpec::FileSystem.matcher?(expected) ? expected.description : expected.inspect
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(Time) || expected.is_a?(DateTime) ||
                    RSpec::FileSystem.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher, Time, or DateTime, but was #{expected.inspect}"
        end

        # Returns nil if the expected birthtime matches the actual birthtime
        # @param path [String] the path of the entry to check
        # @param expected [Object] the expected value to match against the actual value
        # @param failure_messages [Array<String>] the array to append failure messages to
        # @return [Void]
        #
        def self.match(path, expected, failure_messages) # rubocop:disable Metrics/MethodLength
          begin
            actual = File.lstat(path).birthtime
          rescue NotImplementedError
            message = "WARNING: #{key} expectations are not supported for #{path} and will be skipped"
            RSpec.configuration.reporter.message(message)
            return
          end

          case expected
          when Time, DateTime then match_time(actual, expected, failure_messages)
          else                     match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_time(actual, expected, failure_messages)
          return if expected.to_time == actual

          failure_messages << "expected #{key} to be #{expected.to_time.inspect}, but was #{actual.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected #{key} to #{expected.description}, but was #{actual.inspect}"
        end
      end
    end
  end
end
