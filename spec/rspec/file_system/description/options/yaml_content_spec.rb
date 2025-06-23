# frozen_string_literal: true

require 'spec_helper'
require 'rspec/file_system'

RSpec.describe RSpec::FileSystem::Options::YamlContent do
  subject { described_class.description(expected) }

  context 'when the expected value is true' do
    let(:expected) { true }
    it { is_expected.to eq('be yaml content') }
  end

  context 'with a matcher' do
    let(:expected) { include('key' => 'value') }
    it { is_expected.to eq('include {"key" => "value"}') }
  end
end
