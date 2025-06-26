# frozen_string_literal: true

module RSpec
  module PathMatchers
    # Refinements for various classes used in RSpec::PathMatchers
    module Refinements
      # Refinements for Array to provide a `to_sentence` method
      #
      # @example
      #   using RSpec::PathMatchers::Refinements::ArrayRefinements
      #
      module ArrayRefinements
        DEFAULT_SENTENCE_OPTIONS = Data.define(:conjunction, :delimiter, :oxford) do
          def initialize(conjunction: 'and', delimiter: ',', oxford: true)
            super
          end

          def two_word_connector
            "#{delimiter} "
          end

          def last_word_connector
            oxford ? "#{delimiter} #{conjunction} " : " #{conjunction} "
          end
        end.new

        refine Array do
          # Converts an array to a sentence with proper conjunctions and delimiters
          #
          # @example
          #   using RSpec::PathMatchers::Refinements::ArrayRefinements
          #   [].to_sentence # => ''
          #   ['apple'].to_sentence # => 'apple'
          #   ['apple', 'banana'].to_sentence # => 'apple and banana'
          #   ['apple', 'banana', 'cherry'].to_sentence # => 'apple, banana, and cherry'
          #
          # @example using a different conjunction
          #   using RSpec::PathMatchers::Refinements::ArrayRefinements
          #   ['apple', 'banana', 'cherry'].to_sentence(conjunction: 'or')
          #   #=> 'apple, banana, or cherry'
          #
          # @example using a different delimiter
          #   using RSpec::PathMatchers::Refinements::ArrayRefinements
          #   ['apple', 'banana', 'cherry'].to_sentence(delimiter: ';')
          #   #=> 'apple; banana; and cherry'
          #
          # @example without the Oxford comma
          #   using RSpec::PathMatchers::Refinements::ArrayRefinements
          #   ['apple', 'banana', 'cherry'].to_sentence(oxford: false)
          #   #=> 'apple, banana and cherry'
          #
          # @param options_hash [Hash] Options to customize the sentence format
          #
          # @option options_hash [String] :conjunction ('and') The word to use
          #   before the last item in the sentence
          #
          # @option options_hash [String] :delimiter (',') The delimiter to use
          #   between items in the sentence when there are three or more items
          #
          # @option options_hash [Boolean] :oxford (true) Whether to use the
          #   Oxford comma before the conjunction
          #
          # @return [String] The array converted to a sentence
          #
          def to_sentence(options_hash = {})
            options = DEFAULT_SENTENCE_OPTIONS.with(**options_hash)

            case length
            when 0 then ''
            when 1 then first.to_s
            when 2 then join(" #{options.conjunction} ")
            else "#{self[0..-2].join(options.two_word_connector)}#{options.last_word_connector}#{last}"
            end
          end
        end
      end
    end
  end
end
