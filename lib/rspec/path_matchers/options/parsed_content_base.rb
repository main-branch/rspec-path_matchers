# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # Base class for options that parse file content like JSON, and YAML
      class ParsedContentBase < Base
        def self.valid_expected_types = [TrueClass]

        # Reads and parses the file content
        #
        # This method will rescue any parsing errors (e.g., `JSON::ParserError`)
        # and add a descriptive failure instead of crashing.
        #
        # @param (see RSpec::PathMatchers::Options::Base.fetch_actual)
        #
        # @return [Object, FETCH_ERROR] The parsed content (e.g., a Hash) or FETCH_ERROR.
        #
        def self.fetch_actual(path, failures)
          parse(File.read(path))
        rescue parsing_error => e
          message = "expected valid #{content_type} content, but got error: #{e.message}"
          add_failure(message, failures)
          FETCH_ERROR
        end

        # This is the `xxxx_content: true` case. A successful fetch_actual is sufficient
        def self.match_literal(_actual, _expected, _failures); end

        # Compares the parsed content against the given RSpec matcher.
        #
        # @param (see RSpec::PathMatchers::Options::Base.match_matcher)
        #
        # @return [void]
        #
        def self.match_matcher(actual, expected, failures)
          return if expected.matches?(actual)

          message = "expected #{content_type} content to #{expected.description}"
          add_failure(message, failures)
        end

        # Provides a human-readable description for the option
        #
        # Returns a special message for the `json_content: true` case.
        #
        def self.description(expected)
          expected == true ? "be #{content_type.downcase} content" : super
        end

        private_class_method def self.content_type
          raise NotImplementedError, 'Subclasses must implement ParsedContentBase.content_type'
        end

        private_class_method def self.parse(string)
          raise NotImplementedError, 'Subclasses must implement ParsedContentBase.parse'
        end

        private_class_method def self.parsing_error
          raise NotImplementedError, 'Subclasses must implement ParsedContentBase.parsing_error'
        end
      end
    end
  end
end
