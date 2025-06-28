# frozen_string_literal: true

RSpec.describe 'be_dir.description' do
  subject(:description) { matcher.description }

  context 'with no options or block' do
    let(:matcher) { be_dir }
    it { is_expected.to eq('be a directory') }
  end

  context 'with options' do
    let(:matcher) { be_dir(mode: '0755', owner: 'dev') }
    it { is_expected.to eq('be a directory with mode "0755" and owner "dev"') }
  end

  context 'with one expectation on contents' do
    let(:matcher) do
      be_dir.containing(file('a.txt', content: 'hello'))
    end

    let(:expected_description) do
      <<~DESC.chomp
        be a directory containing:
          - have file "a.txt" with content "hello"
      DESC
    end
    it { is_expected.to eq(expected_description) }
  end

  context 'with two expectations on contents' do
    let(:matcher) do
      be_dir.containing(file('a.txt'), dir('subdir'))
    end
    let(:expected_description) do
      <<~DESC.chomp
        be a directory containing:
          - have file "a.txt"
          - have directory "subdir"
      DESC
    end
    it { is_expected.to eq(expected_description) }
  end

  context 'with a deeply nested expectations on contents' do
    let(:matcher) do
      be_dir(owner: 'dev').containing(
        dir('models').containing(file('user.rb', size: be > 100)),
        file('config.ru')
      )
    end
    let(:expected_description) do
      <<~DESC.chomp
        be a directory with owner "dev" containing:
          - have directory "models" containing:
            - have file "user.rb" with size be > 100
          - have file "config.ru"
      DESC
    end
    it { is_expected.to eq(expected_description) }
  end

  context 'with exact expectations on its contents' do
    let(:matcher) do
      be_dir.containing_exactly(file('a.txt'), dir('subdir'))
    end

    let(:expected_description) do
      <<~DESC.chomp
        be a directory containing exactly:
          - have file "a.txt"
          - have directory "subdir"
      DESC
    end

    it { is_expected.to eq(expected_description) }
  end
end
