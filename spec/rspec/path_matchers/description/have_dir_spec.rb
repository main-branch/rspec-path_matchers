# frozen_string_literal: true

RSpec.describe 'have_dir.description' do
  subject(:description) { matcher.description }

  context 'with no options or block' do
    let(:matcher) { have_dir('my_dir') }
    it { is_expected.to eq('have directory "my_dir"') }
  end

  context 'with options' do
    let(:matcher) { have_dir('my_dir', mode: '0755', owner: 'dev') }
    it { is_expected.to eq('have directory "my_dir" with mode "0755" and owner "dev"') }
  end

  context 'with one expectation on its contents' do
    let(:matcher) do
      have_dir('my_dir').containing(file('a.txt', content: 'hello'))
    end
    let(:expected_description) do
      <<~DESC.chomp
        have directory "my_dir" containing:
          - have file "a.txt" with content "hello"
      DESC
    end
    it { is_expected.to eq(expected_description) }
  end

  context 'with two expectations on its contents' do
    let(:matcher) do
      have_dir('my_dir').containing(file('a.txt'), dir('subdir'))
    end

    let(:expected_description) do
      <<~DESC.chomp
        have directory "my_dir" containing:
          - have file "a.txt"
          - have directory "subdir"
      DESC
    end
    it { is_expected.to eq(expected_description) }
  end

  context 'with a deeply nested expectations on its contents' do
    let(:matcher) do
      have_dir('app', owner: 'dev').containing(
        dir('models').containing(file('user.rb', size: be > 100)),
        file('config.ru')
      )
    end

    let(:expected_description) do
      <<~DESC.chomp
        have directory "app" with owner "dev" containing:
          - have directory "models" containing:
            - have file "user.rb" with size be > 100
          - have file "config.ru"
      DESC
    end

    it { is_expected.to eq(expected_description) }
  end

  context 'with exact expectations on its contents' do
    let(:matcher) do
      have_dir('my_dir').containing_exactly(file('a.txt'), dir('subdir'))
    end

    let(:expected_description) do
      <<~DESC.chomp
        have directory "my_dir" containing exactly:
          - have file "a.txt"
          - have directory "subdir"
      DESC
    end

    it { is_expected.to eq(expected_description) }
  end
end
