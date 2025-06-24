# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Matchers
      # The base class for matchers
      class Base # rubocop:disable Metrics/ClassLength
        def initialize(name, **options_hash)
          super()
          @name = name.to_s
          @options = options_factory(*option_keys, **options_hash)
        end

        attr_reader :name, :options, :base_path, :path

        # A human-readable description of the matcher's expectation
        #
        # This is used by RSpec to build the failure message when an `expect(...).to`
        # expectation is not met. For example, if a test asserts `expect(path).to
        # have_file("foo")` and the file does not exist, the failure message will
        # include the output of this method: "expected to have file \"foo\"".
        #
        # @return [String] A description of the matcher
        #
        def description
          desc = "have #{entry_type} #{name.inspect}"
          options_description = build_options_description
          desc += " with #{options_description}" unless options_description.empty?
          desc
        end

        def failure_messages
          @failure_messages ||= []
        end

        def matches?(base_path)
          # It is important to reset failure_messages in case this matcher instance
          # is reused
          @failure_messages = []

          # Phase 1: Validate all options recursively for syntax errors
          validation_errors = []
          collect_validation_errors(validation_errors)
          raise ArgumentError, validation_errors.join(', ') if validation_errors.any?

          # Phase 2: Execute the actual match logic
          execute_match(base_path)
        end

        def collect_negative_validation_errors(errors)
          errors << "The matcher `not_to #{matcher_name}(...)` cannot be given options" if options.any_given?
        end

        # This method is called by RSpec for `expect(...).not_to have_...`
        def does_not_match?(base_path) # rubocop:disable Naming/PredicatePrefix
          # 1. Validate that no options were passed to the negative matcher.
          validation_errors = []
          collect_negative_validation_errors(validation_errors)
          raise ArgumentError, validation_errors.join(', ') if validation_errors.any?

          @base_path = base_path.to_s
          @path = File.join(base_path, name)

          # 2. A negative match SUCCEEDS if the entry of the specified type does NOT exist.
          #    We delegate the type-specific check to the subclass.
          #    The method returns `true` if the entry is NOT of the correct type (pass),
          #    and `false` if it IS of the correct type (fail).
          !correct_type?
        end

        # This is the message RSpec will display if `does_not_match?` returns `false`.
        def failure_message_when_negated
          "expected it not to be a #{entry_type}"
        end

        # Recursively gathers all syntax/validation errors
        #
        # Subclasses (like HaveDirectory) may extend this to recurse into nested
        # matchers.
        #
        # @param errors [Array<String>] An array to append validation error messages to.
        #
        # @return [void]
        #
        # @api private
        #
        def collect_validation_errors(errors)
          validate_option_values(errors)
        end

        def failure_message
          header = "the entry '#{name}' at '#{base_path}' was expected to satisfy the following but did not:"
          # Format single- and multi-line nested messages with proper indentation.
          messages = failure_messages.map do |msg|
            msg.lines.map.with_index do |line, i|
              i.zero? ? "  - #{line.chomp}" : "    #{line.chomp}"
            end.join("\n")
          end.join("\n")
          "#{header}\n#{messages}"
        end

        def correct_type?
          raise NotImplementedError, 'This method should be implemented in a subclass'
        end

        def matcher_name
          raise NotImplementedError, 'This method should be implemented in a subclass'
        end

        protected

        def entry_type
          self.class.name.split('::').last.sub(/^Have/, '').downcase
        end

        # Performs the actual matching against the directory entry
        #
        # This method assumes that collect_validation_errors has already been called
        # and passed. This method is protected so that container matchers (like
        # HaveDirectory) can call it on nested matchers without using .send.
        #
        def execute_match(base_path) # rubocop:disable Naming/PredicateMethod
          @base_path = base_path.to_s
          @path = File.join(base_path, name)

          # Validate existence and type.
          validate_existance(failure_messages)
          return false if failure_messages.any?

          # Validate specific options and nested expectations.
          validate_options
          failure_messages.empty?
        end

        private

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

        def validate_existance(_failure_messages)
          raise NotImplementedError, 'This method should be implemented in a subclass'
        end

        # Validate the options for the current matcher
        #
        # Subclasses will override this to add nested execution.
        def validate_options
          options.members.each do |key|
            expected = options.send(key)
            next if expected == RSpec::PathMatchers::Options::NOT_GIVEN

            option_definition(key).match(path, expected, failure_messages)
          end
        end
      end
    end
  end
end
