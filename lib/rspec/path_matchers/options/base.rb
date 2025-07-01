# frozen_string_literal: true

require 'rspec/path_matchers/refinements'

module RSpec
  module PathMatchers
    module Options
      # Abstract base class for all option matchers
      #
      # @ api public
      #
      class Base
        using RSpec::PathMatchers::Refinements::ArrayRefinements

        # The option key
        #
        # For example, if the option key is `:owner`, then it could be used like this:
        #
        # ```ruby
        # expect(path).to be_file(owner: 'alice')
        # ```
        #
        # @abstract
        #
        # @return [Symbol] the key for this option matcher
        #
        # @api public
        #
        def self.key
          raise NotImplementedError, 'Subclasses must implement Base.key'
        end

        # Adds to `failures` if the entry at path does not match the expectation
        #
        # Entry is a file, directory, or symlink.
        #
        # You can assume that entry at path exists and is the expected type (file,
        # directory, or symlink).
        #
        # This is the main method that the matcher (such as be_dir, be_file, or
        # be_symlink) calls to run its check for an option.
        #
        # @param path [String] the path of the entry to check
        #
        # @param expected [Object] the expected value to match against the entry
        #
        # @param failures [Array<RSpec::PathMatchers::Failure>] the array to append
        # failure objects to (if any)
        #
        # @return [void]
        #
        # @api public
        #
        def self.match(path, expected, failures)
          actual = fetch_actual(path, failures)
          return if actual == FETCH_ERROR
        rescue NotImplementedError
          RSpec.configuration.reporter.message(not_supported_message(path))
        else
          if RSpec::PathMatchers.matcher?(expected)
            match_matcher(actual, expected, failures)
          else
            match_literal(actual, expected, failures)
          end
        end

        # The description of the expectation for this option
        #
        # This is used by RSpec when describing the matcher when tests are run in
        # documentation format or when generating failure messages.
        #
        # @param expected [Object] the expected value to match against the entry
        #
        # @return [String] the description of the expectation
        #
        # @api public
        #
        def self.description(expected)
          RSpec::PathMatchers.matcher?(expected) ? expected.description : expected.inspect
        end

        # Adds to `errors` if the value of `expected` is not valid for this option type
        #
        # The matcher (such as `be_dir`, `be_file`, or `be_symlink`) calls this
        # method to validate the expected value before running the matcher.
        #
        # It checks that the expected value is a RSpec matcher or one of the types
        # listed in {valid_expected_types}.
        #
        # @param expected [Object] the expected value to validate
        #
        # @param errors [Array<String>] the array to append validation errors to
        #
        # @return [void]
        #
        # @api public
        #
        def self.validate_expected(expected, errors)
          return if expected == NOT_GIVEN ||
                    RSpec::PathMatchers.matcher?(expected) ||
                    valid_expected_types.any? { |type| expected.is_a?(type) }

          types = ['Matcher', *valid_expected_types.map(&:name)].to_sentence(conjunction: 'or')

          errors << "expected `#{key}:` to be a #{types}, but it was #{expected.inspect}"
        end

        protected

        # The actual value the expectation will be compared with
        #
        # Depending on what is being checked, this could be a file's owner, group,
        # permissions, content, etc.
        #
        # Return `FETCH_ERROR` if the value could not be fetched, which will
        # cause the matcher to fail.
        #
        # @param path [String] the path of the entry to check
        #
        # @param failures [Array<RSpec::PathMatchers::Failure>] the array to append
        # failure objects to (if any)
        #
        # @return [Object, FETCH_ERROR] the actual value of the entry at path or FETCH_ERROR
        #
        # @api protected
        #
        private_class_method def self.fetch_actual(path, failures)
          raise NotImplementedError, 'Subclasses must implement Base.fetch_actual'
        end

        # The valid types (in addition to an RSpec matcher) for the option value
        #
        # For instance, if the option key is `:owner`, then the option value could be
        # a `String` specifying the owner name as in `be_file(owner: 'alice')`.
        #
        # @example specify that only an RSpec matcher is allowed
        #   def self.valid_expected_types = []
        #
        # @example specify that the option value must be an RSpec matcher or a String
        #   def self.valid_expected_types = [String]
        #
        # @example specify that the option value can be a matcher, String, or Regexp
        #   def self.valid_expected_types = [String, Regexp]
        #
        # @return [Array<Class>] an array of valid types for the option value
        #
        # @api protected
        #
        private_class_method def self.valid_expected_types = []

        # Converts the expected value to a normalized form for comparison
        #
        # This is used to ensure that the expected value is in a consistent format
        # for comparison, such as converting a DateTime object to a Time object.
        #
        # This is NOT called if expected is an RSpec matcher.
        #
        # @example normalize the expected value to a Time object
        #   def self.normalize_expected_literal(expected) = expected.to_time
        #
        # @param expected [Object] the expected value to normalize
        #
        # @return [Object] the normalized expected value
        #
        # @api protected
        #
        private_class_method def self.normalize_expected_literal(expected) = expected

        # Checks if the actual value matches the expected value
        #
        # This is called whenever expected is not an RSpec matcher. By default,
        # it does a simple equality check using `==`.
        #
        # Option subclasses should override this method to provide custom matching
        # logic, such as when `expected` is a Regexp.
        #
        # @example check if the actual value matches a Regexp or a String
        #   def self.literal_match?(actual, expected)
        #     expected.is_a?(Regexp) ? expected.match?(actual) : expected == actual
        #   end
        #
        # @param actual [Object] the actual value fetched from the file system
        #
        # @param expected [Object] the expected literal value to match against
        #
        # @return [Boolean] true if they match, false otherwise
        #
        # @api protected
        #
        private_class_method def self.literal_match?(actual, expected) = actual == expected

        # Add to `failures` if actual value matches the normalized expected value
        #
        # This is called when expected is not an RSpec matcher.
        #
        # Option subclasses should override this method to provide custom matching
        # logic or custom failure messages.
        #
        # @param actual [Object] the actual value fetched from the file system
        #
        # @param expected [Object] the expected literal value to match against
        #
        # @param failures [Array<RSpec::PathMatchers::Failure>] the array to append
        # failure objects to (if any)
        #
        # @return [void]
        #
        # @api protected
        #
        private_class_method def self.match_literal(actual, expected, failures)
          expected = normalize_expected_literal(expected)

          return if literal_match?(actual, expected)

          add_failure(literal_failure_message(actual, expected), failures)
        end

        private_class_method def self.add_failure(message, failures)
          failures << RSpec::PathMatchers::Failure.new('.', message)
        end

        # Generates a failure message for a literal match failure
        #
        # This is used when the actual value does not match the expected value.
        # It provides a clear message indicating what was expected and what was
        # actually found.
        #
        # Option subclasses should override this method to provide custom failure
        # messages for specific types of options.
        #
        # @example generate a failure message for a literal match failure
        #  def self.literal_failure_message(actual, expected)
        #    if expected.is_a?(Regexp)
        #      "expected #{key} to match #{expected.inspect}, but it was #{actual.inspect}"
        #    else
        #      "expected #{key} to be #{expected.inspect}, but it was #{actual.inspect}"
        #    end
        #  end
        #
        # @param actual [Object] the actual value fetched from the file system
        #
        # @param expected [Object] the expected literal value to match against
        #
        # @return [String] the failure message
        #
        # @api protected
        #
        private_class_method def self.literal_failure_message(actual, expected)
          "expected #{key} to be #{expected.inspect}, but it was #{actual.inspect}"
        end

        # Add to `failures` if actual value matches the normalized expected value
        #
        # This is called when expected is an RSpec matcher.
        #
        # Option subclasses should override this method to provide custom matching
        # logic or custom failure messages.
        #
        # @param actual [Object] the actual value fetched from the file system
        #
        # @param expected [RSpec::Matchers::Matcher] the expected matcher to match against
        #
        # @param failures [Array<RSpec::PathMatchers::Failure>] the array to append
        # failure objects to (if any)
        #
        # @return [void]
        #
        # @api protected
        #
        private_class_method def self.match_matcher(actual, expected, failures)
          return if expected.matches?(actual)

          add_failure(matcher_failure_message(actual, expected), failures)
        end

        # Generates a failure message for a matcher match failure
        #
        # This is used when the actual value does not match the expected value.
        # It provides a clear message indicating what was expected and what was
        # actually found.
        #
        # Option subclasses should override this method to provide custom failure
        # messages for specific types of options.
        #
        # @param actual [Object] the actual value fetched from the file system
        #
        # @param expected [Object] the expected literal value to match against
        #
        # @return [String] the failure message
        #
        # @api protected
        #
        private_class_method def self.matcher_failure_message(actual, expected)
          "expected #{key} to #{expected.description}, but it was #{actual.inspect}"
        end

        # Warning message for unsupported expectations
        #
        # This is used when the platform or file system does not support the
        # expectation, such as when trying to check file ownership on a platform that
        # does not support it.
        #
        # @param path [String] the path of the entry that the expectation was attempted on
        #
        # @return [String] a warning message indicating that the expectation is not supported
        #
        # @api private
        #
        private_class_method def self.not_supported_message(path)
          "WARNING: #{key} expectations are not supported for #{path} and will be skipped"
        end
      end
    end
  end
end
