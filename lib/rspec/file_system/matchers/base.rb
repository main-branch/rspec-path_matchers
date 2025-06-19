# frozen_string_literal: true

module RSpec
  module FileSystem
    module Matchers
      # The base class for file system matchers
      class Base
        def initialize(name, **options_hash)
          super()
          @name = name.to_s
          @options = options_factory(*option_keys, **options_hash)
        end

        attr_reader :name, :options, :base_path, :path

        # This helper method acts as a factory for our options classes.
        # It defines a Data class with the given members and injects our
        # custom initializer to handle default values.
        def options_factory(*members, **options_hash)
          Data.define(*members) do
            def initialize(**kwargs)
              # Default every member to the NOT_GIVEN sentinel
              defaults = self.class.members.to_h { |member| [member, RSpec::FileSystem::Options::NOT_GIVEN] }
              final_args = defaults.merge(kwargs)
              super(**final_args)
            end
          end.new(**options_hash)
        end

        def option_definition(key)
          option_definitions.find { |definition| definition.key == key }
        end

        def option_keys
          option_definitions.map(&:key)
        end

        def failure_messages
          @failure_messages ||= []
        end

        def matches?(base_path)
          @base_path = base_path.to_s
          @path = File.join(base_path, name)

          validate_option_values
          raise ArgumentError, failure_messages.join(', ') if failure_messages.any?

          validate_existance(failure_messages)
          return false if failure_messages.any?

          validate_options
          failure_messages.empty?
        end

        def failure_message
          "the file '#{name}' did not satisfy its expectations:\n" +
            failure_messages.join("\n")
        end

        private

        # Ensure the user provided option-values are of the expected type and format
        #
        # Populates the `failure_messages` array with the errors found.
        #
        # @return [Void]
        #
        # @api private
        #
        def validate_option_values
          options.members.filter_map do |key|
            expected = options.send(key)

            next if expected == RSpec::FileSystem::Options::NOT_GIVEN

            option_definition(key).validate_expected(expected, failure_messages)
          end
        end

        # Ensure the entry at `path` exists and is of the expected type
        #
        # Populates the `failure_messages` array with the errors found.
        #
        # There are typically two error cases:
        #
        # 1. The entry does not exist at all
        # 2. The entry exists, but is not of the expected type (e.g., a file when a directory was expected)
        #
        # @return [Void]
        #
        # @abstract Subclass and override this method to implement specific validation logic.
        #
        # @api private
        #
        def validate_existance(failure_messages)
          raise NotImplementedError, 'This method should be implemented in a subclass'
        end

        # Ensure the entry at `path` matches the expectations defined in `options`
        #
        # Populates the `failure_messages` array with the errors found.
        #
        # @return [Void]
        #
        # @api private
        #
        def validate_options
          options.members.each do |key|
            expected = options.send(key)
            next if expected == RSpec::FileSystem::Options::NOT_GIVEN

            option_definition(key).match(path, expected, failure_messages)
          end
        end
      end
    end
  end
end
