# frozen_string_literal: true

require_relative 'base'

module RSpec
  module FileSystem
    module Matchers
      # An RSpec matcher checks for the existence and properties of a file
      class HaveFile < Base
        OPTIONS = [
          RSpec::FileSystem::Options::Atime,
          RSpec::FileSystem::Options::Birthtime,
          RSpec::FileSystem::Options::Content,
          RSpec::FileSystem::Options::Ctime,
          RSpec::FileSystem::Options::Group,
          RSpec::FileSystem::Options::JsonContent,
          RSpec::FileSystem::Options::Mode,
          RSpec::FileSystem::Options::Mtime,
          RSpec::FileSystem::Options::Owner,
          RSpec::FileSystem::Options::Size,
          RSpec::FileSystem::Options::YamlContent
        ].freeze

        def option_definitions = OPTIONS

        def correct_type? = File.file?(path)

        def matcher_name = 'have_file'

        protected

        def validate_existance(failure_messages)
          return nil if File.file?(path)

          failure_messages <<
            if File.exist?(path)
              'expected it to be a regular file'
            else
              'expected it to exist'
            end
        end
      end
    end
  end
end
