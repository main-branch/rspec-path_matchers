# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Options::Base do
  describe '.key' do
    subject { described_class.key }
    it_behaves_like 'an abstract class method'
  end

  describe '.fetch_actual' do
    subject { described_class.send(:fetch_actual, double, double) }
    it_behaves_like 'an abstract class method'
  end
end
