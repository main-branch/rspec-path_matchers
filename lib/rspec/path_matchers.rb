# frozen_string_literal: true

require 'rspec'

module RSpec
  # A collection of matchers for testing directory entries
  #
  # This module provides the main DSL methods for use in RSpec tests.
  #
  # @example
  #   require 'rspec/path_matchers'
  #
  #   RSpec.configure do |config|
  #     config.include RSpec::PathMatchers
  #   end
  #
  #   RSpec.describe '/var/log' do
  #     it { is_expected.to be_dir.containing(file('syslog')) }
  #   end
  #
  module PathMatchers
    # Returns true if object is a matcher
    # @api private
    def self.matcher?(object)
      object.respond_to?(:matches?) && object.respond_to?(:description)
    end

    # A simple, immutable structure to hold failure data internally.
    # @api private
    Failure = Data.define(:relative_path, :message)

    # @!group Top-Level Matchers

    # Creates a matcher that tests if the subject path is a directory
    #
    # @param options_hash [Hash] A hash of attribute matchers (e.g., mode:, owner:).
    #
    # @return [RSpec::PathMatchers::Matchers::DirectoryMatcher] The matcher instance.
    #
    # @example Basic existence check
    #   expect('/var/log').to be_dir
    #
    # @example Checking attributes
    #   expect('/tmp').to be_dir(mode: '1777')
    #
    def be_dir(**options_hash)
      RSpec::PathMatchers::Matchers::DirectoryMatcher.new('', matcher_name: __method__, **options_hash)
    end

    # Creates a matcher that tests if the subject path is a file
    #
    # @param options_hash [Hash] A hash of attribute matchers (e.g., content:, size:).
    # @return [RSpec::PathMatchers::Matchers::FileMatcher] The matcher instance.
    #
    # @example
    #   expect('/etc/hosts').to be_file(content: include('localhost'))
    #
    def be_file(**options_hash)
      RSpec::PathMatchers::Matchers::FileMatcher.new('', matcher_name: __method__, **options_hash)
    end

    # Creates a matcher that tests if the subject path is a symbolic link
    #
    # @param options_hash [Hash] A hash of attribute matchers (e.g., target:).
    # @return [RSpec::PathMatchers::Matchers::SymlinkMatcher] The matcher instance.
    #
    # @example
    #   expect('/usr/bin/ruby').to be_symlink(target: a_string_ending_with('ruby3.2'))
    #
    def be_symlink(**options_hash)
      RSpec::PathMatchers::Matchers::SymlinkMatcher.new('', matcher_name: __method__, **options_hash)
    end

    # @!endgroup

    # @!group Top-Level Child Matchers

    # A matcher to test if the subject path has a child directory with the given name
    #
    # @param entry_name [String] The name of the expected child directory.
    # @param options_hash [Hash] A hash of attribute matchers.
    # @return [RSpec::PathMatchers::Matchers::DirectoryMatcher]
    #
    # @example
    #   expect('/tmp').to have_dir('new_project', owner: 'root')
    #
    def have_dir(entry_name, **options_hash) # rubocop:disable Naming/PredicatePrefix
      RSpec::PathMatchers::Matchers::DirectoryMatcher.new(entry_name, matcher_name: __method__, **options_hash)
    end

    # A matcher to test if the subject path has a child file with the given name
    #
    # @param entry_name [String] The name of the expected child file.
    # @param options_hash [Hash] A hash of attribute matchers.
    # @return [RSpec::PathMatchers::Matchers::FileMatcher]
    #
    # @example
    #   expect('/etc').to have_file('hosts', content: /localhost/)
    #
    def have_file(entry_name, **options_hash) # rubocop:disable Naming/PredicatePrefix
      RSpec::PathMatchers::Matchers::FileMatcher.new(entry_name, matcher_name: __method__, **options_hash)
    end

    # A matcher to test if the subject path has a child symlink with the given name
    #
    # @param entry_name [String] The name of the expected child symlink.
    # @param options_hash [Hash] A hash of attribute matchers.
    # @return [RSpec::PathMatchers::Matchers::SymlinkMatcher]
    #
    # @example
    #   expect('/usr/local/bin').to have_symlink('ruby')
    #
    def have_symlink(entry_name, **options_hash) # rubocop:disable Naming/PredicatePrefix
      RSpec::PathMatchers::Matchers::SymlinkMatcher.new(entry_name, matcher_name: __method__, **options_hash)
    end

    # @!endgroup

    # @!group Nested Entry Declarations

    # Declares an expectation for a file within a directory
    #
    # Intended for use as an argument to #containing or #containing_exactly.
    #
    # @param name [String] The name of the expected file.
    # @param options_hash [Hash] A hash of attribute matchers (e.g., content:, size:).
    # @return [RSpec::PathMatchers::Matchers::FileMatcher] The matcher object.
    #
    def file(name, **options_hash)
      RSpec::PathMatchers::Matchers::FileMatcher.new(name, matcher_name: __method__, **options_hash)
    end

    # Declares an expectation for a directory within a directory
    #
    # Intended for use as an argument to #containing or #containing_exactly.
    #
    # @param name [String] The name of the expected directory.
    # @param options_hash [Hash] A hash of attribute matchers (e.g., mode:, owner:).
    # @return [RSpec::PathMatchers::Matchers::DirectoryMatcher] The matcher object.
    #
    def dir(name, **options_hash)
      RSpec::PathMatchers::Matchers::DirectoryMatcher.new(name, matcher_name: __method__, **options_hash)
    end

    # Declares an expectation for a symbolic link within a directory
    #
    # Intended for use as an argument to #containing or #containing_exactly.
    #
    # @param name [String] The name of the expected symlink.
    # @param options_hash [Hash] A hash of attribute matchers (e.g., target:).
    # @return [RSpec::PathMatchers::Matchers::SymlinkMatcher] The matcher object.
    #
    def symlink(name, **options_hash)
      RSpec::PathMatchers::Matchers::SymlinkMatcher.new(name, matcher_name: __method__, **options_hash)
    end

    # Declares an expectation that a directory with the given name does NOT exist
    #
    # Intended for use as an argument to #containing or #containing_exactly.
    #
    # @param name [String] The name of the directory that should be absent.
    # @return [RSpec::PathMatchers::Matchers::NoEntryMatcher]
    #
    def no_dir_named(name)
      RSpec::PathMatchers::Matchers::NoEntryMatcher.new(name, matcher_name: __method__, entry_type: :directory)
    end

    # Declares an expectation that a file with the given name does NOT exist
    #
    # Intended for use as an argument to #containing or #containing_exactly.
    #
    # @param name [String] The name of the file that should be absent.
    # @return [RSpec::PathMatchers::Matchers::NoEntryMatcher]
    #
    def no_file_named(name)
      RSpec::PathMatchers::Matchers::NoEntryMatcher.new(name, matcher_name: __method__, entry_type: :file)
    end

    # Declares an expectation that a symlink with the given name does NOT exist
    #
    # Intended for use as an argument to #containing or #containing_exactly.
    #
    # @param name [String] The name of the symlink that should be absent.
    # @return [RSpec::PathMatchers::Matchers::NoEntryMatcher]
    #
    def no_symlink_named(name)
      RSpec::PathMatchers::Matchers::NoEntryMatcher.new(name, matcher_name: __method__, entry_type: :symlink)
    end

    # @!endgroup
  end
end

require_relative 'path_matchers/version'
require_relative 'path_matchers/options'

require_relative 'path_matchers/matchers/directory_matcher'
require_relative 'path_matchers/matchers/file_matcher'
require_relative 'path_matchers/matchers/no_entry_matcher'
require_relative 'path_matchers/matchers/symlink_matcher'

require_relative 'path_matchers/refinements'
