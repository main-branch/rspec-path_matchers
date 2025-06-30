# frozen_string_literal: true

RSpec.describe 'be_file.description' do
  let(:matcher) { file('file.txt', **options) }
  subject(:description) { matcher.description }

  context 'with no options' do
    let(:options) { {} }
    it {
      is_expected.to eq('have file "file.txt"')
    }
  end

  context 'with one option' do
    let(:options) { { size: 123 } }
    it { is_expected.to eq('have file "file.txt" with size 123') }
  end

  context 'with two options' do
    let(:options) { { owner: 'root', mode: '0644' } }
    it { is_expected.to eq('have file "file.txt" with mode "0644" and owner "root"') }
  end
end
