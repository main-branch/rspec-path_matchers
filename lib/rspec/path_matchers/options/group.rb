# frozen_string_literal: true

require_relative 'etc_base'

module RSpec
  module PathMatchers
    module Options
      # group: <expected>
      class Group < EtcBase
        def self.key = :group
        def self.stat_attribute = :gid
        def self.etc_method = :getgrgid
      end
    end
  end
end
