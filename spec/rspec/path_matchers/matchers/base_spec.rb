# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Matchers::Base do
  context 'when not subclassed' do
    let(:name) { double('name') }
    let(:matcher_name) { double('matcher_name') }

    let(:base_matcher) { described_class.new(name, matcher_name:) }

    describe '.correct_type?' do
      subject { base_matcher.send(:correct_type?) }
      it_behaves_like 'an abstract method'
    end

    describe '.entry_type' do
      subject { base_matcher.send(:entry_type) }
      it_behaves_like 'an abstract method'
    end

    describe '.validate_existance' do
      let(:failures) { double('failures') }
      subject { base_matcher.send(:validate_existance) }
      it_behaves_like 'an abstract method'
    end
  end
end
