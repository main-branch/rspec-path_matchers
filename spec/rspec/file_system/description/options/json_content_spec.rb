# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::JsonContent do
  subject { described_class.description(expected) }

  context 'when the expected value is true' do
    let(:expected) { true }
    it { is_expected.to eq('true') }
  end

  context 'with a matcher' do
    let(:expected) { include('key' => 'value') }
    it { is_expected.to eq('include {"key" => "value"}') }
  end
end
