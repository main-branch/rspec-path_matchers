# frozen_string_literal: true

require 'yaml'

require_relative 'parsed_content_base'

module RSpec
  module PathMatchers
    module Options
      # yaml_content: <expected>
      class YamlContent < ParsedContentBase
        def self.key = :yaml_content
        private_class_method def self.content_type  = 'YAML'
        private_class_method def self.parse(string) = YAML.safe_load(string)
        private_class_method def self.parsing_error = Psych::SyntaxError
      end
    end
  end
end
