# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # target_exist: <expected>
      class SymlinkTargetExist < Base
        def self.key = :target_exist
        def self.valid_expected_types = [TrueClass, FalseClass]

        def self.fetch_actual(path, _failure_messages) # rubocop:disable Naming/PredicateMethod
          File.exist?(File.expand_path(File.readlink(path), File.dirname(path)))
        end
      end
    end
  end
end
