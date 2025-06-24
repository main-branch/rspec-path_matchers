# frozen_string_literal: true

require_relative 'base'
require_relative 'directory_contents_inspector'

module RSpec
  module FileSystem
    module Matchers
      # An RSpec matcher that checks for the existence and properties of a directory
      #
      class HaveDirectory < Base
        OPTIONS = [
          RSpec::FileSystem::Options::Atime,
          RSpec::FileSystem::Options::Birthtime,
          RSpec::FileSystem::Options::Ctime,
          RSpec::FileSystem::Options::Group,
          RSpec::FileSystem::Options::Mode,
          RSpec::FileSystem::Options::Mtime,
          RSpec::FileSystem::Options::Owner
        ].freeze

        attr_reader :nested_matchers, :exact

        # Initializes the matcher with the directory name and options
        #
        # @param name [String] The name of the directory
        #
        # @param exact [Boolean] The directory must contain only entries declared in the specification block
        #
        # @param options_hash [Hash] A hash of attribute matchers (e.g., mode:, owner:)
        #
        # @param specification_block [Proc] A specification block that defines the expected directory contents
        #
        def initialize(name, exact: false, **options_hash, &specification_block)
          super(name, **options_hash)

          @exact = exact
          @nested_matchers = []
          return unless specification_block

          inspector = DirectoryContentsInspector.new
          inspector.instance_eval(&specification_block)
          @nested_matchers = inspector.nested_matchers
        end

        def description
          desc = super
          desc += ' exactly' if exact
          return desc if nested_matchers.empty?

          nested_descriptions = nested_matchers.map do |matcher|
            matcher.description.lines.map.with_index do |line, i|
              i.zero? ? "- #{line.chomp}" : "  #{line.chomp}"
            end.join("\n")
          end

          "#{desc} containing:\n  #{nested_descriptions.join("\n  ")}"
        end

        def collect_negative_validation_errors(errors)
          super
          return unless nested_matchers.any?

          errors << "The matcher `not_to #{matcher_name}(...)` cannot be given a specification block"
        end

        def collect_validation_errors(errors)
          super

          errors << "`exact:` must be true or false, but was #{exact.inspect}" unless [true, false].include?(exact)

          # Recursively validate nested matchers.
          nested_matchers.each { |matcher| matcher.collect_validation_errors(errors) }
        end

        def option_definitions = OPTIONS
        def correct_type? = File.directory?(path)
        def matcher_name = 'have_dir'

        protected

        # Overrides Base to add the exactness check after other validations.
        def validate_options
          super # Validate this directory's own options first.

          nested_matchers.each do |matcher|
            failure_messages << matcher.failure_message unless matcher.execute_match(path)
          end

          # If any of the declared expectations failed, we stop here.
          # The user needs to fix those first.
          return unless failure_messages.empty?

          check_for_unexpected_entries if exact
        end

        def validate_existance(failure_messages)
          return if File.directory?(path)

          failure_messages << (File.exist?(path) ? 'expected it to be a directory' : 'expected it to exist')
        end

        private

        # Checks for any files/directories on disk that were not declared in the block.
        def check_for_unexpected_entries
          positively_declared_entries = nested_matchers.reject do |m|
            m.is_a?(RSpec::FileSystem::Matchers::HaveNoEntry)
          end.map(&:name)

          actual_entries = Dir.children(path)
          unexpected_entries = actual_entries - positively_declared_entries

          return if unexpected_entries.empty?

          message = build_unexpected_entries_message(unexpected_entries)
          failure_messages << message
        end

        def build_unexpected_entries_message(unexpected_entries)
          "did not expect entries #{unexpected_entries.inspect} to be present"
        end
      end
    end
  end
end
