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

  context 'with the exact option' do
    let(:matcher) { be_dir(exact: true) }
    it { is_expected.to eq('be a directory exactly') }
  end

  context 'with one nested matcher' do
    let(:matcher) do
      be_dir do
        file 'a.txt', content: 'hello'
      end
    end
    let(:expected_description) do
      <<~DESC.chomp
        be a directory containing:
          - have file "a.txt" with content "hello"
      DESC
    end
    it { is_expected.to eq(expected_description) }
  end

  context 'with two nested matchers' do
    let(:matcher) do
      be_dir do
        file 'a.txt'
        dir 'subdir'
      end
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

  context 'with a deeply nested structure' do
    let(:matcher) do
      be_dir(owner: 'dev') do
        dir 'models' do
          file 'user.rb', size: be > 100
        end
        file 'config.ru'
      end
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
end
