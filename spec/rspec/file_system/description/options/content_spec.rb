# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::Content do
  subject { described_class.description(expected) }

  context 'when the expected value is a String' do
    let(:expected) { 'hello world' }
    it { is_expected.to eq('"hello world"') }
  end

  context 'when the expected value is a Regexp' do
    let(:expected) { /hello/ }
    it { is_expected.to eq('/hello/') }
  end

  context 'with a matcher' do
    let(:expected) { start_with('hello') }
    it { is_expected.to eq('start with "hello"') }
  end
end
