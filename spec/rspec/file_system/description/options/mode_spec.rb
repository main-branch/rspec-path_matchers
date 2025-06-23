# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::Mode do
  subject { described_class.description(expected) }

  context 'when the expected value is a String' do
    let(:expected) { '0644' }
    it { is_expected.to eq('"0644"') }
  end

  context 'with a matcher' do
    let(:expected) { match(/^0\d{3}$/) }
    it { is_expected.to eq('match /^0\\d{3}$/') }
  end
end
