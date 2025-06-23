# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Options::Mtime do
  subject { described_class.description(expected) }

  let(:now) { Time.new(2025, 6, 22, 15, 23, 0, '-07:00') }

  context 'when the expected value is a Time' do
    let(:expected) { now }
    it { is_expected.to eq(now.inspect) }
  end

  context 'when the expected value is a DateTime' do
    let(:expected) { now.to_datetime }
    it { is_expected.to eq(now.to_datetime.inspect) }
  end

  context 'with a matcher' do
    let(:expected) { be_within(10).of(now) }
    it { is_expected.to eq('be within 10 of 2025-06-22 15:23:00.000000000 -0700') }
  end
end
