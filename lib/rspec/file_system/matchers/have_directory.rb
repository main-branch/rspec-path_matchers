# frozen_string_literal: true

require_relative 'base'
require_relative 'directory_contents_inspector'

module RSpec
  module FileSystem
    module Matchers
      # An RSpec matcher checks for the existence and properties of a directory
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

        attr_reader :nested_matchers

        def initialize(name, **options_hash, &block)
          super(name, **options_hash)
          @nested_matchers = []
          return unless block

          inspector = DirectoryContentsInspector.new
          inspector.instance_eval(&block)
          @nested_matchers = inspector.nested_matchers
        end

        # (see Base#description)
        def description
          desc = super
          return desc if nested_matchers.empty?

          nested_descriptions = nested_matchers.map do |matcher|
            matcher.description.lines.map.with_index do |line, i|
              i.zero? ? "- #{line.chomp}" : "  #{line.chomp}"
            end.join("\n")
          end

          "#{desc} containing:\n  #{nested_descriptions.join("\n  ")}"
        end

        # Overrides Base to add recursive validation for nested matchers
        def collect_validation_errors(errors)
          super # Validate this directory's own options first.
          nested_matchers.each do |matcher|
            matcher.collect_validation_errors(errors)
          end
        end

        def option_definitions = OPTIONS

        protected

        # Overrides Base to add recursive execution for nested matchers
        def validate_options
          super # Validate this directory's own options first.

          # Execute the nested matchers against this directory's path
          nested_matchers.each do |matcher|
            # If a nested matcher fails, append its detailed failure message
            failure_messages << matcher.failure_message unless matcher.execute_match(path)
          end
        end

        def validate_existance(failure_messages)
          return nil if File.directory?(path)

          failure_messages <<
            if File.exist?(path)
              'expected it to be a directory'
            else
              'expected it to exist'
            end
        end
      end
    end
  end
end
