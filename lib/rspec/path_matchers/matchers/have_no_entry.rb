# In lib/rspec/path_matchers/matchers/have_no_entry.rb
# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Matchers
      # Asserts that a directory entry of a specific entry_type does NOT exist.
      # This is a simple, internal matcher-like object.
      #
      # @api private
      class HaveNoEntry
        attr_reader :name, :matcher_name, :entry_type

        # Initializes the matcher with the entry name and type
        #
        # @param name [String] The name of the entry to check
        #
        # @param entry_type [Symbol] The type of the entry (:file, :directory, or :symlink)
        #
        def initialize(name, entry_type:)
          @name = name
          @entry_type = entry_type
          @base_path = nil
          @path = nil
        end

        # The core logic. Returns `true` if the expectation is met (the entry is absent).
        def execute_match(base_path) # rubocop:disable Naming/PredicateMethod
          @base_path = base_path
          @path = File.join(base_path, @name)

          case entry_type
          when :file then !File.file?(@path)
          when :directory then !File.directory?(@path)
          else !File.symlink?(@path)
          end
        end

        # The failure message if `execute_match` returns `false`.
        def failure_message
          "expected #{entry_type} '#{@name}' not to be found at '#{@base_path}', but it exists"
        end

        # Provide a description for the `have_dir` block's output.
        def description
          "not have #{entry_type} #{@name.inspect}"
        end

        # Provide a stub for this method, which is called by HaveDirectory
        # but is not needed for this simple matcher.
        def collect_validation_errors(_errors); end
      end
    end
  end
end
