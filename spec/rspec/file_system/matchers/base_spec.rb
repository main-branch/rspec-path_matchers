# frozen_string_literal: true

RSpec.describe RSpec::FileSystem::Matchers::Base do
  context 'when subclassed to create a matcher' do
    let(:matcher) do
      Class.new(described_class) do
        def option_definitions = []
      end.new('test_file')
    end

    describe '#matches?' do
      context 'when not overridden in the subclass' do
        it 'raises NotImplementedError' do
          expect { matcher.matches?('/tmp') }.to raise_error(NotImplementedError)
        end
      end
    end

    describe '#correct_type?' do
      context 'when not overridden in the subclass' do
        it 'raises NotImplementedError' do
          expect { matcher.correct_type? }.to raise_error(NotImplementedError)
        end
      end
    end

    describe '#matcher_name' do
      context 'when not overridden in the subclass' do
        it 'raises NotImplementedError' do
          expect { matcher.matcher_name }.to raise_error(NotImplementedError)
        end
      end
    end
  end
end
