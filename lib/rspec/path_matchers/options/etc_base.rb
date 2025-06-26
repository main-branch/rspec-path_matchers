# frozen_string_literal: true

require_relative 'file_stat_base'

module RSpec
  module PathMatchers
    module Options
      # Base class for options that use the Etc module (owner, group)
      class EtcBase < FileStatBase
        def self.valid_expected_types = [String]

        def self.match(path, expected, failure_messages)
          # Skip the check entirely if the platform doesn't support it
          return unless supported_platform?

          super
        end

        private_class_method def self.supported_platform?
          return true if Etc.respond_to?(etc_method)

          RSpec.configuration.reporter.message(
            "WARNING: #{key} expectations are not supported on this platform and will be skipped."
          )
          false
        end

        # Fetches the UID/GID from stat and looks up the name via Etc
        private_class_method def self.fetch_actual(path, _failure_messages)
          Etc.public_send(etc_method, super).name
        end

        # Abstract method for subclasses to define :getpwuid or :getgrgid
        private_class_method def self.etc_method
          raise NotImplementedError, 'Subclasses must implement EtcBase.etc_method'
        end
      end
    end
  end
end
