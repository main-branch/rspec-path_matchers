# frozen_string_literal: true

require 'spec_helper'
require 'rspec/file_system'

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

  context 'with the exact option' do
    let(:matcher) { have_dir('my_dir', exact: true) }
    it { is_expected.to eq('have directory "my_dir" exactly') }
  end

  context 'with one nested matcher' do
    let(:matcher) do
      have_dir('my_dir') do
        file 'a.txt', content: 'hello'
      end
    end
    let(:expected_description) do
      <<~DESC.chomp
        have directory "my_dir" containing:
          - have file "a.txt" with content "hello"
      DESC
    end
    it { is_expected.to eq(expected_description) }
  end

  context 'with two nested matchers' do
    let(:matcher) do
      have_dir('my_dir') do
        file 'a.txt'
        dir 'subdir'
      end
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

  context 'with a deeply nested structure' do
    let(:matcher) do
      have_dir('app', owner: 'dev') do
        dir 'models' do
          file 'user.rb', size: be > 100
        end
        file 'config.ru'
      end
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
end
