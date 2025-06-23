# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::SymlinkTargetType do
  subject { described_class.description(expected) }

  context 'when the expected value is a String' do
    let(:expected) { 'file' }
    it { is_expected.to eq('"file"') }
  end

  context 'when the expected value is a Symbol' do
    let(:expected) { :directory }
    it { is_expected.to eq(':directory') }
  end

  context 'with a matcher' do
    let(:expected) { eq('file') }
    it { is_expected.to eq('eq "file"') }
  end
end
