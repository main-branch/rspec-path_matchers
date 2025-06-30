# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Matchers
      # An RSpec matcher that checks for the existence and properties of a symlink
      #
      class SymlinkMatcher < Base
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

        def entry_type = :symlink

        def option_definitions = OPTIONS

        def correct_type? = File.symlink?(path)

        protected

        def validate_existance
          return nil if File.symlink?(path)

          message =
            if File.exist?(path)
              'expected it to be a symlink'
            else
              'expected it to exist'
            end

          add_failure(message, failures)
        end
      end
    end
  end
end
