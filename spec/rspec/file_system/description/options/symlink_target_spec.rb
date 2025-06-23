# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::SymlinkTarget do
  subject { described_class.description(expected) }

  context 'when the expected value is a String' do
    let(:expected) { '/path/to/target' }
    it { is_expected.to eq('"/path/to/target"') }
  end

  context 'with a matcher' do
    let(:expected) { end_with('target') }
    it { is_expected.to eq('end with "target"') }
  end
end
