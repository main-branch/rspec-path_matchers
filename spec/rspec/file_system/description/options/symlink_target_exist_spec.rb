# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::SymlinkTargetExist do
  subject { described_class.description(expected) }

  context 'when the expected value is true' do
    let(:expected) { true }
    it { is_expected.to eq('true') }
  end

  context 'when the expected value is false' do
    let(:expected) { false }
    it { is_expected.to eq('false') }
  end

  context 'with a matcher' do
    let(:expected) { be(true) }
    it { is_expected.to eq('equal true') }
  end
end
