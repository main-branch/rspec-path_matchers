# frozen_string_literal: true

require_relative 'base'

module RSpec
  module PathMatchers
    module Options
      # Base class for options whose actual value comes from File::Stat
      class FileStatBase < Base
        # Implements fetch_actual using File.stat
        def self.fetch_actual(path, _failure_messages)
          File.public_send(stat_source_method, path).public_send(stat_attribute)
        end

        # The method used on a File object to get the stat information
        #
        # This should be `:stat` to follow symlinks and `:lstat` for symbolic links.
        #
        # The default is `:stat`, which means it will follow symbolic links.
        #
        # @return [Symbol]
        #
        # @api protected
        #
        private_class_method def self.stat_source_method = :stat

        # The name of the File::Stat attribute used to get the actual value
        #
        # @example getting file size
        #   def self.stat_attribute = :size
        #
        # @return [Symbol]
        #
        # @raise [NotImplementedError] if not implemented in subclass
        #
        # @abstract
        #
        # @api protected
        #
        private_class_method def self.stat_attribute
          raise NotImplementedError, 'Subclasses must implement FileStatBase.stat_attribute'
        end
      end
    end
  end
end
