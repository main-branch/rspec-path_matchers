# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Matchers
      # An RSpec matcher checks for the existence and properties of a file
      class HaveFile < Base
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
