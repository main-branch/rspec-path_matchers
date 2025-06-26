# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Options::FileStatBase do
  describe '.stat_attribute' do
    subject { described_class.send(:stat_attribute) }
    it_behaves_like 'an abstract class method'
  end
end
