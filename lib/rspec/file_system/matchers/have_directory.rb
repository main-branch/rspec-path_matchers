# frozen_string_literal: true

require_relative 'base'

module RSpec
  module FileSystem
    module Matchers
      # An RSpec matcher checks for the existence and properties of a file
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

        def option_definitions = OPTIONS

        protected

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
