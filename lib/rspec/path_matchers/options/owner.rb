# frozen_string_literal: true

require_relative 'etc_base'

module RSpec
  module PathMatchers
    module Options
      # group: <expected>
      class Owner < EtcBase
        def self.key = :owner
        def self.stat_attribute = :uid
        def self.etc_method = :getpwuid
      end
    end
  end
end
