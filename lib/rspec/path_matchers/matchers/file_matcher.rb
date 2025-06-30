# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Matchers
      # An RSpec matcher checks for the existence and properties of a file
      #
      class FileMatcher < Base
        OPTIONS = [
          RSpec::PathMatchers::Options::Atime,
          RSpec::PathMatchers::Options::Birthtime,
          RSpec::PathMatchers::Options::Content,
          RSpec::PathMatchers::Options::Ctime,
          RSpec::PathMatchers::Options::Group,
          RSpec::PathMatchers::Options::JsonContent,
          RSpec::PathMatchers::Options::Mode,
          RSpec::PathMatchers::Options::Mtime,
          RSpec::PathMatchers::Options::Owner,
          RSpec::PathMatchers::Options::Size,
          RSpec::PathMatchers::Options::YamlContent
        ].freeze

        def entry_type = :file

        def option_definitions = OPTIONS

        def correct_type? = File.file?(path)

        protected

        def validate_existance
          return nil if File.file?(path)

          message =
            if File.exist?(path)
              'expected it to be a regular file'
            else
              'expected it to exist'
            end

          add_failure(message, failures)
        end
      end
    end
  end
end
