# frozen_string_literal: true

require 'spec_helper'
require 'rspec/path_matchers'

RSpec.describe 'be_symlink.description' do
  let(:matcher) { symlink('a.link', **options) }
  subject(:description) { matcher.description }

  context 'with no options' do
    let(:options) { {} }
    it { is_expected.to eq('have symlink "a.link"') }
  end

  context 'with one option' do
    let(:options) { { target: 'a.file' } }
    it { is_expected.to eq('have symlink "a.link" with target "a.file"') }
  end

  context 'with two options' do
    let(:options) { { target: 'a.file', owner: 'user' } }
    it { is_expected.to eq('have symlink "a.link" with owner "user" and target "a.file"') }
  end
end
