# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Matchers::Base do
  context 'when subclassed to create a matcher and validate_existance is not overridden' do
    let(:matcher) do
      Class.new(described_class) do
        def option_definitions = []
      end.new('test_file')
    end

    describe '#matches?' do
      it 'raises NotImplementedError' do
        expect { matcher.matches?('/tmp') }.to raise_error(NotImplementedError)
      end
    end
  end
end
