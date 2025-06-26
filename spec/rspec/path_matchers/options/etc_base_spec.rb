# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Options::EtcBase do
  describe '.etc_method' do
    subject { described_class.send(:etc_method) }
    it_behaves_like 'an abstract class method'
  end
end
