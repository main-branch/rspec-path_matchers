# frozen_string_literal: true

module RSpec
  module FileSystem
    module Matchers
      # Provides the DSL for the `have_dir` matcher's block
      #
      # It is responsible for creating and collecting the nested matchers
      # without immediately executing them.
      #
      # @api private
      #
      class DirectoryContentsInspector
        def initialize
          @nested_matchers = []
        end

        attr_reader :nested_matchers

        # Defines an expectation for a file within the directory.
        def file(name, **options)
          nested_matchers << RSpec::FileSystem::Matchers::HaveFile.new(name, **options)
        end

        # Defines an expectation for a nested directory.
        def dir(name, ...)
          nested_matchers << RSpec::FileSystem::Matchers::HaveDirectory.new(name, ...)
        end

        # Defines an expectation for a symlink within the directory.
        def symlink(name, **options)
          nested_matchers << RSpec::FileSystem::Matchers::HaveSymlink.new(name, **options)
        end
      end
    end
  end
end
