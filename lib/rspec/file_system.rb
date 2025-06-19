# frozen_string_literal: true

require 'rspec'

module RSpec
  # RSpec::FileSystem is a collection of matchers for testing file system properties
  module FileSystem
    def self.matcher?(object)
      object.respond_to?(:matches?) && object.respond_to?(:description)
    end
  end
end
require_relative 'file_system/version'
require_relative 'file_system/options'

require_relative 'file_system/matchers/have_file'
require_relative 'file_system/matchers/have_directory'
require_relative 'file_system/matchers/have_symlink'

def have_file(name, **options_hash) # rubocop:disable Naming/PredicatePrefix
  RSpec::FileSystem::Matchers::HaveFile.new(name, **options_hash)
end

def have_dir(name, **options_hash) # rubocop:disable Naming/PredicatePrefix
  RSpec::FileSystem::Matchers::HaveDirectory.new(name, **options_hash)
end

def have_symlink(name, **options_hash) # rubocop:disable Naming/PredicatePrefix
  RSpec::FileSystem::Matchers::HaveSymlink.new(name, **options_hash)
end
