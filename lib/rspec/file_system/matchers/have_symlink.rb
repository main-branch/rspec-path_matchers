# frozen_string_literal: true

require_relative 'base'

module RSpec
  module FileSystem
    module Matchers
      # An RSpec matcher checks for the existence and properties of a file
      class HaveSymlink < Base
        OPTIONS = [
          RSpec::FileSystem::Options::SymlinkAtime,
          RSpec::FileSystem::Options::SymlinkBirthtime,
          RSpec::FileSystem::Options::SymlinkCtime,
          RSpec::FileSystem::Options::SymlinkGroup,
          RSpec::FileSystem::Options::SymlinkMtime,
          RSpec::FileSystem::Options::SymlinkOwner,
          RSpec::FileSystem::Options::SymlinkTarget,
          RSpec::FileSystem::Options::SymlinkTargetExist,
          RSpec::FileSystem::Options::SymlinkTargetType
        ].freeze

        def option_definitions = OPTIONS

        def correct_type? = File.symlink?(path)

        def matcher_name = 'have_symlink'

        protected

        def validate_existance(failure_messages)
          return nil if File.symlink?(path)

          failure_messages <<
            if File.exist?(path)
              'expected it to be a symlink'
            else
              'expected it to exist'
            end
        end
      end
    end
  end
end
