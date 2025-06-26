# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Options::ParsedContentBase do
  describe '.content_type' do
    subject { described_class.send(:content_type) }
    it_behaves_like 'an abstract class method'
  end

  describe '.parse' do
    subject { described_class.send(:parse, double) }
    it_behaves_like 'an abstract class method'
  end

  describe '.parsing_error' do
    subject { described_class.send(:parsing_error) }
    it_behaves_like 'an abstract class method'
  end
end
