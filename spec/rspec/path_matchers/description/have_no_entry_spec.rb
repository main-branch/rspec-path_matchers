# frozen_string_literal: true

RSpec.describe 'have_no_entry.description' do
  let(:matcher) { RSpec::PathMatchers::Matchers::NoEntryMatcher.new(name, matcher_name:, entry_type:) }
  let(:matcher_name) { 'have_no_entry' }

  describe '#description' do
    subject { matcher.description }

    context 'for file type' do
      let(:name) { 'file.txt' }
      let(:entry_type) { 'file' }
      it { is_expected.to eq('not have file "file.txt"') }
    end
    context 'for file directory' do
      let(:name) { 'dir' }
      let(:entry_type) { 'directory' }
      it { is_expected.to eq('not have directory "dir"') }
    end
    context 'for file symlink' do
      let(:name) { 'symlink.txt' }
      let(:entry_type) { 'symlink' }
      it { is_expected.to eq('not have symlink "symlink.txt"') }
    end
  end
end
