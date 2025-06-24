# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Options::Group do
  subject { described_class.description(expected) }

  context 'when the expected value is a String' do
    let(:expected) { 'wheel' }
    it { is_expected.to eq('"wheel"') }
  end

  context 'with a matcher' do
    let(:expected) { an_instance_of(String) }
    it { is_expected.to eq('an instance of String') }
  end
end
