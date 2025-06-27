# frozen_string_literal: true

require 'rspec'

module RSpec
  # RSpec::PathMatchers is a collection of matchers for testing directory entries
  module PathMatchers
    # Returns true if object is a matcher
    def self.matcher?(object)
      object.respond_to?(:matches?) && object.respond_to?(:description)
    end
  end
end

require_relative 'path_matchers/version'
require_relative 'path_matchers/options'

require_relative 'path_matchers/matchers/have_file'
require_relative 'path_matchers/matchers/have_directory'
require_relative 'path_matchers/matchers/have_symlink'
require_relative 'path_matchers/matchers/have_no_entry'

require_relative 'path_matchers/refinements'

def be_dir(**options_hash, &)
  RSpec::PathMatchers::Matchers::HaveDirectory.new('', matcher_name: __method__, **options_hash, &)
end

def have_file(name, **options_hash) # rubocop:disable Naming/PredicatePrefix
  RSpec::PathMatchers::Matchers::HaveFile.new(name, matcher_name: __method__, **options_hash)
end

def have_dir(name, **options_hash, &) # rubocop:disable Naming/PredicatePrefix
  RSpec::PathMatchers::Matchers::HaveDirectory.new(name, matcher_name: __method__, **options_hash, &)
end

def have_symlink(name, **options_hash) # rubocop:disable Naming/PredicatePrefix
  RSpec::PathMatchers::Matchers::HaveSymlink.new(name, matcher_name: __method__, **options_hash)
end
