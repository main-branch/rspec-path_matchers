# frozen_string_literal: true

module RSpec
  module FileSystem
    module Options
      # mtime: <expected>
      class Mtime
        def self.key = :mtime

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

        # Returns nil if the path matches the expected size
        # @param path [String] the path of the entry to check
        # @return [String, nil]
        #
        def self.match(path, expected, failure_messages)
          actual = File.stat(path).mtime
          case expected
          when Time, DateTime then match_time(actual, expected, failure_messages)
          else                     match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_time(actual, expected, failure_messages)
          return if expected.to_time == actual

          failure_messages << "expected mtime to be #{expected.to_time.inspect}, but was #{actual.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected mtime to #{expected.description}, but was #{actual.inspect}"
        end
      end
    end
  end
end
