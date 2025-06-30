# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Matchers
      # The base class for matchers
      #
      # Implements the [RSpec matcher
      # protocol](https://rspec.info/documentation/3.13/rspec-expectations/RSpec/Matchers/MatcherProtocol.html)
      # for value expectations including:
      #
      # - `#matches?(base_path)` - checks if the matcher matches the given base_path
      # - `#failure_message` - returns a human-readable failure message
      # - `#actual` - returns the actual value that was matched against
      # - `#expected` - returns the expected value that was matched against
      # - `#description` - returns a human-readable description of the matcher
      # - `#does_not_match?(base_path)` - checks if the matcher does not match the given base_path
      # - `#failure_message_when_negated` - returns a human-readable failure message for negative matches
      #
      class Base # rubocop:disable Metrics/ClassLength
        # Create a new matcher instance
        #
        # Subclasses may override this to provide additional arguments or options.
        # They should call `super` to ensure the base class is initialized correctly.
        #
        # @param entry_name [String] The name of the entry to match against
        #
        #   - If entry_name is empty, the matcher will match against the base_path
        #     directly (this is the path passed to `matches?` or `does_not_match?`).
        #   - If entry_name is NOT empty, the matcher will match against
        #     File.join(base_path, entry_name)
        #
        # @param matcher_name [Symbol] The matcher name (e.g. :have_dir, :have_file,
        #   etc.) to use in descriptions and messages
        #
        # @param options_hash [Hash] Options for the matcher passed to the options
        #   factory to get an options object
        #
        def initialize(entry_name, matcher_name:, **options_hash)
          super()
          @entry_name = entry_name.to_s
          @matcher_name = matcher_name
          @options = options_factory(*option_keys, **options_hash)
          @failures = []
        end

        # @attribute [r] options
        #
        # The matcher options loaded from the options_hash passed to the initializer
        #
        # @return [Object] A Data object containing the options
        #
        attr_reader :options

        # @attribute [r] base_path
        #
        # The base path against which the matcher is applied
        #
        # @return [String]
        #
        attr_reader :base_path

        # @attribute [r] path
        #
        # The full path to the entry being matched against
        #
        # @return [String]
        #
        attr_reader :path

        # @attribute [r] matcher_name
        #
        # The name of this matcher, used for descriptions and messages
        #
        # @return [Symbol] The matcher name (e.g. :have_dir, :have_file, etc.)
        #
        attr_reader :matcher_name

        # @attribute [r] failures
        #
        # An array of failures that describe why the matcher did not match the actual
        # value
        #
        # Only populated after `matches?` or `execute_match` is called
        #
        # @return [Array<RSpec::PathMatchers::Failure>]
        #
        attr_reader :failures

        # @attribute [r] entry_name
        #
        # The name of the entry being matched against or an empty String
        #
        # If `entry_name` is empty, the matcher will match against the base_path
        # directly. If `entry_name` is not empty, the matcher will match against
        # `File.join(base_path, entry_name)`.
        #
        # @return [String]
        #
        def entry_name
          @entry_name || base_path.basename
        end

        # A human-readable description of the matcher's expectation
        #
        # This description is used by RSpec formatters (e.g., `--format
        # documentation`) to provide output about the specification itself. It is NOT
        # used to build the detailed failure message when an expectation fails.
        #
        # Subclasses can override this method to add to or provide a more specific
        # description based on the entry type, options, or other factors.
        #
        # @return [String]
        #
        def description
          desc = (@entry_name.empty? ? "be a #{entry_type}" : "have #{entry_type} #{entry_name.inspect}")
          options_description = build_options_description
          desc += " with #{options_description}" unless options_description.empty?
          desc
        end

        # Returns `true` if the matcher matches the actual value
        #
        # If `false` is returned, the `failures` array will be populated with
        # human-readable error messages that describe why the match failed.
        #
        # @param base_path [Object] The base_path together with entry_name determine the actual value
        #
        # @return [Boolean] `true` if the matcher matches, `false` otherwise
        #
        # @raise [ArgumentError] if there are errors in the matcher or its options
        #
        def matches?(base_path)
          # Phase 1: Validate all options for syntax errors
          validation_errors = []
          collect_validation_errors(validation_errors)
          raise ArgumentError, validation_errors.join(', ') if validation_errors.any?

          # Phase 2: Execute the actual match logic
          execute_match(base_path)
        end

        def failure_message
          header = "#{path} was not as expected:"
          grouped_failures = failures.group_by(&:relative_path)

          messages = grouped_failures.map do |relative_path, failures_for_path|
            format_failure_group(relative_path, failures_for_path)
          end

          "#{header}\n#{messages.join("\n")}"
        end

        # This method is called by RSpec for `expect(...).not_to have_...`
        def does_not_match?(base_path) # rubocop:disable Naming/PredicatePrefix
          # Phase 1: Validate all options for syntax errors (in this case options are not allowed)
          validation_errors = []
          collect_negative_validation_errors(validation_errors)
          raise ArgumentError, validation_errors.join(', ') if validation_errors.any?

          @base_path = base_path.to_s
          @path = @entry_name.empty? ? base_path : File.join(base_path, entry_name)

          # Phase 2: Execute the actual match logic
          #
          # A negative match SUCCEEDS if the entry of the specified type does NOT
          # exist. We delegate the type-specific check to the subclass.
          !correct_type?
        end

        # This is the message RSpec will display if `does_not_match?` returns `false`.
        def failure_message_when_negated
          "expected it not to be a #{entry_type}"
        end

        protected

        # Add to `errors` if the matcher is not defined correctly
        #
        # Subclasses may override this method to provide additional checking. For
        # instance, BeDirectory extends this to add validation for nested matchers.
        #
        # A nesting matcher (such as BeDirectory) may call this method on the
        # nested matchers to collect all validation errors before raising an
        # ArgumentError.
        #
        # @param errors [Array<String>] An array to populate with validation error
        # messages
        #
        # @return [void]
        #
        # @api private
        #
        def collect_validation_errors(errors)
          validate_option_values(errors)
        end

        # Returns `true` if `path` exists and is of the correct type for this matcher
        #
        # Subclasses must implement this method to check the type of the entry. For
        # example, BeFile checks if the path is a regular file; BeDirectory, a
        # directory; and BeSymlink, a symlink.
        #
        # @return [Boolean]
        #
        # @abstract
        #
        def correct_type?
          raise NotImplementedError, 'Subclasses must implement Base#correct_type?'
        end

        # Add to errors if options were passed to the negative matcher
        #
        # This method is called by RSpec for `expect(...).not_to <matcher>...`
        #
        # Subclasses can override this to add additional validation.
        #
        # @param errors [Array<String>] An array to append validation error messages to
        #
        # @return [void]
        #
        def collect_negative_validation_errors(errors)
          errors << "The matcher `not_to #{matcher_name}(...)` cannot be given options" if options.any_given?
        end

        # Subclasses should define their own option definitions
        #
        # @return [Array<RSpec::PathMatchers::Options::Base>] An array of option definitions
        #
        def option_definitions = []

        # The type of entry this matcher is checking for
        #
        # @return [Symbol] The entry type (e.g. :file, :directory, :symlink, ...)
        #
        def entry_type
          raise NotImplementedError, 'Subclasses must implement Base#entry_type'
        end

        # Performs the actual matching against the directory entry
        #
        # This method assumes that collect_validation_errors has already been called
        # and passed.
        #
        # This method is protected so that container matchers (like BeDirectory)
        # can call it on nested matchers without using .send.
        #
        def execute_match(base_path) # rubocop:disable Naming/PredicateMethod
          # It is important to reset failures in case this matcher is reused
          @failures = []

          @base_path = base_path.to_s
          @path = @entry_name.empty? ? base_path : File.join(base_path, entry_name)

          # Validate existence and type.
          validate_existance
          return false if failures.any?

          # Validate specific options and nested expectations.
          validate_options
          failures.empty?
        end

        private

        # Formats a group of failures for a single relative path.
        #
        # @param relative_path [String] The path of the failure relative to the subject.
        # @param failures_for_path [Array<Failure>] A list of failures for that path.
        # @return [String] A formatted string block for this group of failures.
        #
        def format_failure_group(relative_path, failures_for_path)
          indented_errors = failures_for_path.map { |f| "      #{f.message}" }.join("\n")

          if relative_path == '.'
            # For failures on the subject itself, just show the indented errors.
            indented_errors
          else
            # For failures on a child, show the path and then the indented errors.
            path_line = "  - #{relative_path}"
            "#{path_line}\n#{indented_errors}"
          end
        end

        def build_options_description
          descriptions = options.to_h.filter_map do |key, value|
            next if value == RSpec::PathMatchers::Options::NOT_GIVEN

            "#{key.to_s.chomp('?')} #{option_definition(key).description(value)}"
          end
          descriptions.join(' and ')
        end

        def options_factory(*members, **options_hash)
          Data.define(*members) do
            def initialize(**kwargs)
              # Default every member to the NOT_GIVEN sentinel
              defaults = self.class.members.to_h { |member| [member, RSpec::PathMatchers::Options::NOT_GIVEN] }
              final_args = defaults.merge(kwargs)
              super(**final_args)
            end

            def any_given?
              to_h.values.any? { |v| v != RSpec::PathMatchers::Options::NOT_GIVEN }
            end
          end.new(**options_hash)
        end

        def option_definition(key)
          option_definitions.find { |definition| definition.key == key }
        end

        def option_keys
          option_definitions.map(&:key)
        end

        # Ensure the user provided option-values are of the expected type and format
        def validate_option_values(errors)
          options.members.filter_map do |key|
            expected = options.send(key)
            next if expected == RSpec::PathMatchers::Options::NOT_GIVEN

            option_definition(key).validate_expected(expected, errors)
          end
        end

        def validate_existance
          raise NotImplementedError, 'Subclasses must implement Base#validate_existance'
        end

        # Validate the options for the current matcher
        #
        # Subclasses may override this to add additional validation logic. For
        # instance, BeDirectory extends this to check nested matchers.
        #
        def validate_options
          options.members.each do |key|
            expected = options.send(key)
            next if expected == RSpec::PathMatchers::Options::NOT_GIVEN

            option_definition(key).match(path, expected, failures)
          end
        end

        def add_failure(message, failures)
          failures << RSpec::PathMatchers::Failure.new('.', message)
        end
      end
    end
  end
end
