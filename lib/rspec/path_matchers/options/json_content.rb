# frozen_string_literal: true

require 'json'

require_relative 'parsed_content_base'

module RSpec
  module PathMatchers
    module Options
      # json_content: <expected>
      class JsonContent < ParsedContentBase
        def self.key = :json_content
        private_class_method def self.content_type  = 'JSON'
        private_class_method def self.parse(string) = JSON.parse(string)
        private_class_method def self.parsing_error = JSON::ParserError
      end
    end
  end
end
