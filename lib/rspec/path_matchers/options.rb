# frozen_string_literal: true

module RSpec
  module PathMatchers
    module Options
      # The value used to indicate that an option was not given by the user
      NOT_GIVEN = Object.new.freeze
      FETCH_ERROR = Object.new.freeze
    end
  end
end

# Load all option classes
require_relative 'options/atime'
require_relative 'options/birthtime'
require_relative 'options/content'
require_relative 'options/ctime'
require_relative 'options/group'
require_relative 'options/json_content'
require_relative 'options/mode'
require_relative 'options/mtime'
require_relative 'options/owner'
require_relative 'options/size'
require_relative 'options/yaml_content'

require_relative 'options/symlink_atime'
require_relative 'options/symlink_birthtime'
require_relative 'options/symlink_ctime'
require_relative 'options/symlink_group'
require_relative 'options/symlink_mtime'
require_relative 'options/symlink_owner'
require_relative 'options/symlink_target'
require_relative 'options/symlink_target_exist'
require_relative 'options/symlink_target_type'
