# frozen_string_literal: true

RSpec.describe RSpec::PathMatchers::Matchers::HaveNoEntry do
  let(:matcher) { described_class.new(name, entry_type:) }

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
