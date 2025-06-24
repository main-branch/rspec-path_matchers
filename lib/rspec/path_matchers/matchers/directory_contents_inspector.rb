# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Matchers
      # Provides the DSL for the `have_dir` matcher's block
      #
      # It is responsible for creating and collecting the nested matchers
      # without immediately executing them.
      #
      # @api private
      #
      class DirectoryContentsInspector
        # By including RSpec::Matchers, we make methods like `be`, `eq`, `include`,
        # `an_instance_of`, etc., available within the `have_dir` block
        #
        include RSpec::Matchers

        def initialize
          @nested_matchers = []
        end

        attr_reader :nested_matchers

        # Defines an expectation for a file within the directory.
        def file(name, **options)
          nested_matchers << RSpec::PathMatchers::Matchers::HaveFile.new(name, **options)
        end

        # Defines an expectation for a nested directory.
        def dir(name, ...)
          nested_matchers << RSpec::PathMatchers::Matchers::HaveDirectory.new(name, ...)
        end

        # Defines an expectation for a symlink within the directory.
        def symlink(name, **options)
          nested_matchers << RSpec::PathMatchers::Matchers::HaveSymlink.new(name, **options)
        end

        # Defines an expectation that a file does NOT exist within the directory.
        def no_file(name)
          nested_matchers << RSpec::PathMatchers::Matchers::HaveNoEntry.new(name, type: :file)
        end

        # Defines an expectation that a directory does NOT exist within the directory.
        def no_dir(name)
          nested_matchers << RSpec::PathMatchers::Matchers::HaveNoEntry.new(name, type: :directory)
        end

        # Defines an expectation that a symlink does NOT exist within the directory.
        def no_symlink(name)
          nested_matchers << RSpec::PathMatchers::Matchers::HaveNoEntry.new(name, type: :symlink)
        end
      end
    end
  end
end
