# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::SymlinkGroup do
  subject { described_class.description(expected) }

  context 'when the expected value is a String' do
    let(:expected) { 'staff' }
    it { is_expected.to eq('"staff"') }
  end

  context 'with a matcher' do
    let(:expected) { an_instance_of(String) }
    it { is_expected.to eq('an instance of String') }
  end
end
