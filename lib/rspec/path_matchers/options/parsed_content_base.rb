# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # Base class for options that parse file content like JSON, and YAML
      class ParsedContentBase < Base
        def self.valid_expected_types = [TrueClass]

        def self.fetch_actual(path, failure_messages)
          parse(File.read(path))
        rescue parsing_error => e
          failure_messages << "expected valid #{content_type} content, but got error: #{e.message}"
          FETCH_ERROR
        end

        # This is the `xxxx_content: true` case. A successful fetch_actual is sufficient.
        def self.match_literal(_actual, _expected, _failure_messages); end

        def self.match_matcher(actual, expected, failure_messages)
          return if expected.matches?(actual)

          failure_messages << "expected #{content_type} content to #{expected.description}"
        end

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
