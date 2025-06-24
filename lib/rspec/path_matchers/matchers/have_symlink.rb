# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Matchers
      # An RSpec matcher checks for the existence and properties of a file
      class HaveSymlink < Base
        OPTIONS = [
          RSpec::PathMatchers::Options::SymlinkAtime,
          RSpec::PathMatchers::Options::SymlinkBirthtime,
          RSpec::PathMatchers::Options::SymlinkCtime,
          RSpec::PathMatchers::Options::SymlinkGroup,
          RSpec::PathMatchers::Options::SymlinkMtime,
          RSpec::PathMatchers::Options::SymlinkOwner,
          RSpec::PathMatchers::Options::SymlinkTarget,
          RSpec::PathMatchers::Options::SymlinkTargetExist,
          RSpec::PathMatchers::Options::SymlinkTargetType
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
