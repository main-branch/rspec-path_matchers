# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Options::Size do
  subject { described_class.description(expected) }

  context 'when the expected value is an Integer' do
    let(:expected) { 42 }
    it { is_expected.to eq('42') }
  end

  context 'with a matcher' do
    let(:expected) { be > 100 }
    it { is_expected.to eq('be > 100') }
  end
end
