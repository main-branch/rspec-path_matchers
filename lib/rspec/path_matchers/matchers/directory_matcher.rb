# frozen_string_literal: true

require_relative 'base'
require 'pathname'

module RSpec
  module PathMatchers
    module Matchers
      # An RSpec matcher that checks for the existence and properties of a directory
      #
      class DirectoryMatcher < Base
        OPTIONS = [
          RSpec::PathMatchers::Options::Atime,
          RSpec::PathMatchers::Options::Birthtime,
          RSpec::PathMatchers::Options::Ctime,
          RSpec::PathMatchers::Options::Group,
          RSpec::PathMatchers::Options::Mode,
          RSpec::PathMatchers::Options::Mtime,
          RSpec::PathMatchers::Options::Owner
        ].freeze

        # @attribute [r] exact
        #
        # If true, the dir must contain only entries given in `containing_exactly`
        #
        # The default is false, meaning the directory can contain additional entries.
        #
        # @return [Boolean]
        #
        attr_reader :exact

        # Initializes the matcher with the directory name and options
        #
        # @param entry_name [String] The name of the directory relative to the subject or empty
        #
        # @param matcher_name [Symbol] The name of the DSL method used to create this matcher
        #
        # @param options_hash [Hash] A hash of attribute matchers (e.g., mode:, owner:)
        #
        def initialize(entry_name, matcher_name:, **options_hash)
          super

          @exact = false
          @nested_matchers = []
        end

        def containing(*matchers)
          @nested_matchers << matchers
          @exact = false
          self
        end

        def containing_exactly(*matchers)
          @nested_matchers << matchers
          @exact = true
          self
        end

        def description
          desc = super
          return desc if nested_matchers.empty?

          nested_descriptions = nested_matchers.map do |matcher|
            matcher.description.lines.map.with_index do |line, i|
              i.zero? ? "- #{line.chomp}" : "  #{line.chomp}"
            end.join("\n")
          end

          "#{desc} containing#{' exactly' if exact}:\n  #{nested_descriptions.join("\n  ")}"
        end

        def entry_type = :directory
        def option_definitions = OPTIONS
        def correct_type? = File.directory?(path)

        def collect_negative_validation_errors(errors)
          super
          return unless nested_matchers.any?

          errors << "The matcher `not_to #{matcher_name}(...)` cannot have expectations on its contents"
        end

        def collect_validation_errors(errors)
          super

          if @nested_matchers.size > 1
            errors << 'Collectively, `#containing` and `#containing_exactly` may be called only once'
          end

          # Recursively validate nested matchers.
          nested_matchers.each { |matcher| matcher.collect_validation_errors(errors) }
        end

        protected

        # Overrides Base to add the exactness check after other validations.
        def validate_options
          # Validate this directory's own options (mode, owner, etc.)
          super

          # Validate the nested entries described in `containing`
          validate_nested_matchers

          return unless failures.empty?

          # If using `containing_exactly`, check for unexpected entries
          check_for_unexpected_entries if exact
        end

        def validate_existance
          return if File.directory?(path)

          message = (File.exist?(path) ? 'expected it to be a directory' : 'expected it to exist')
          add_failure(message, failures)
        end

        private

        # This new private method encapsulates the logic for checking children.
        def validate_nested_matchers
          nested_matchers.each do |matcher|
            next if matcher.execute_match(path)

            matcher.failures.each do |failure|
              new_relative_path = (Pathname.new(matcher.entry_name) + Pathname.new(failure.relative_path)).to_s
              failures << RSpec::PathMatchers::Failure.new(new_relative_path, failure.message)
            end
          end
        end

        # An array of nested matchers that define the expected contents of the
        # directory
        #
        # One element is added to the @nested_matchers array for each call to
        # `containing` or `containing_exactly`. Since `containing` or
        # `containing_exactly` are allowed only once per matcher, an error will be
        # logged during validation if the size of this array is greater than one.
        #
        # Each element in @nested_matchers is itself an array of the matchers given
        # in each `containing` or `containing_exactly` call.
        #
        # This method returns the first element of @nested_matchers (or an empty
        # array of @nested_matchers is itself empty).
        #
        # @return [Array<RSpec::PathMatchers::Matchers::Base>]
        #
        def nested_matchers
          @nested_matchers.first || []
        end

        # Checks for any files/directories on disk that were not declared in the block.
        def check_for_unexpected_entries
          positively_declared_entries = nested_matchers.reject do |m|
            m.is_a?(RSpec::PathMatchers::Matchers::NoEntryMatcher)
          end.map(&:entry_name)

          actual_entries = Dir.children(path)
          unexpected_entries = actual_entries - positively_declared_entries

          return if unexpected_entries.empty?

          message = build_unexpected_entries_message(unexpected_entries)
          add_failure(message, failures)
        end

        def build_unexpected_entries_message(unexpected_entries)
          "contained unexpected entries #{unexpected_entries.sort.inspect}"
        end
      end
    end
  end
end
