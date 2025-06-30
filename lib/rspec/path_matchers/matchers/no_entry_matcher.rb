# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Matchers
      # Asserts that a directory entry of a specific entry_type does NOT exist.
      # This is a simple, internal matcher-like object.
      #
      # @api private
      class NoEntryMatcher
        attr_reader :entry_name, :entry_type, :base_path, :path

        # Initializes the matcher with the entry name and type
        #
        # @param entry_name [String] The name of the entry to check
        #
        # @param matcher_name [Symbol] The name of the DSL method used to create this matcher
        #
        # @param entry_type [Symbol] The type of the entry (:file, :directory, or :symlink)
        #
        def initialize(entry_name, matcher_name:, entry_type:)
          @entry_name = entry_name
          @matcher_name = matcher_name
          @entry_type = entry_type
          @base_path = nil
          @path = nil
        end

        # The core logic. Returns `true` if the expectation is met (the entry is absent).
        def execute_match(base_path) # rubocop:disable Naming/PredicateMethod
          @base_path = base_path
          @path = File.join(base_path, entry_name)

          case entry_type
          when :file then !File.file?(path)
          when :directory then !File.directory?(path)
          else !File.symlink?(path)
          end
        end

        # The failure message if `execute_match` returns `false`.
        def failure_message
          "expected #{entry_type} '#{entry_name}' not to be found at '#{base_path}', but it exists"
        end

        # Returns the failure message in an array as expected by the DirectoryMatcher
        #
        # @return [Array<String>]
        #
        def failures
          [RSpec::PathMatchers::Failure.new('.', failure_message)]
        end

        # Provides a human-readable description for use in test output.
        def description
          "not have #{entry_type} #{entry_name.inspect}"
        end

        # Called by DirectoryMatcher but is not needed for this simple matcher
        def collect_validation_errors(_errors); end
      end
    end
  end
end
