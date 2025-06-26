# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Refinements::ArrayRefinements do
  using RSpec::PathMatchers::Refinements::ArrayRefinements

  describe '#to_sentence' do
    context 'with default options' do
      it 'returns an empty string for an empty array' do
        expect([].to_sentence).to eq('')
      end

      it 'returns the single item for a one-element array' do
        expect(['apple'].to_sentence).to eq('apple')
      end

      it 'joins two items with "and"' do
        expect(%w[apple banana].to_sentence).to eq('apple and banana')
      end

      it 'joins three items with commas and "and"' do
        expect(%w[apple banana cherry].to_sentence).to eq('apple, banana, and cherry')
      end
    end

    context 'with the option `conjunction: "or"`' do
      it 'should use the given conjunction' do
        expect(%w[apple banana cherry].to_sentence(conjunction: 'or')).to eq('apple, banana, or cherry')
      end
    end

    context 'with the option `delimiter: ";"`' do
      it 'should use the given delimiter' do
        expect(%w[apple banana cherry].to_sentence(delimiter: ';')).to eq('apple; banana; and cherry')
      end
    end

    context 'with the option `oxford: false`' do
      it 'should not add the Oxford comma' do
        expect(%w[apple banana cherry].to_sentence(oxford: false)).to eq('apple, banana and cherry')
      end
    end
  end
end
