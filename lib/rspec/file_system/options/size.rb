# frozen_string_literal: true

module RSpec
  module FileSystem
    module Options
      # size: <expected>
      class Size
        def self.key = :size

        def self.description(expected)
          RSpec::FileSystem.matcher?(expected) ? expected.description : expected.to_s
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(Integer) ||
                    RSpec::FileSystem.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher or an Integer, but was #{expected.inspect}"
        end

        # Returns nil if the path matches the expected size
        # @param path [String] the path of the entry to check
        # @return [String, nil]
        #
        def self.match(path, expected, failure_messages)
          actual = File.size(path)
          case expected
          when Integer then match_integer(actual, expected, failure_messages)
          else              match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_integer(actual, expected, failure_messages)
          return if expected == actual

          failure_messages << "expected size to be #{expected.inspect}, but was #{actual.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected size to #{expected.description}, but was #{actual.inspect}"
        end
      end
    end
  end
end
