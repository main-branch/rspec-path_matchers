# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Options
      # target_type: <expected>
      class SymlinkTargetType
        def self.key = :target_type

        def self.description(expected)
          RSpec::PathMatchers.matcher?(expected) ? expected.description : expected.inspect
        end

        def self.validate_expected(expected, failure_messages)
          return if expected == NOT_GIVEN ||
                    expected.is_a?(String) || expected.is_a?(Symbol) ||
                    RSpec::PathMatchers.matcher?(expected)

          failure_messages <<
            "expected `#{key}:` to be a Matcher, a String, or a Symbol but was #{expected.inspect}"
        end

        # Populates failure_messages if expected value does not match actual value
        # @param path [String] the path of the entry to check
        # @param expected [Object] the expected value
        # @param failure_messages [Array<String>] the array to populate with failure messages
        # @return [Void]
        #
        def self.match(path, expected, failure_messages)
          begin
            actual = File.ftype(File.expand_path(File.readlink(path), File.dirname(path)))
          rescue Errno::ENOENT => e
            failure_messages << "expected the symlink target to exist, but got error: #{e.message}"
            return
          end

          case expected
          when String, Symbol then match_string(actual, expected, failure_messages)
          else                     match_matcher(actual, expected, failure_messages)
          end
        end

        # private methods

        private_class_method def self.match_string(actual, expected, failure_messages)
          return if expected.to_s == actual

          failure_messages << "expected #{key} to be #{expected.to_s.inspect}, but was #{actual.inspect}"
        end

        private_class_method def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected #{key} to #{expected.description}, but was #{actual.inspect}"
        end
      end
    end
  end
end
