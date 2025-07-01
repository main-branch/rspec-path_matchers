# spec/rspec/path_matchers/failure_messages_spec.rb
# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'failure messages' do
  include RSpec::PathMatchers

  around do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  let(:base_dir) { @tmpdir }

  context 'when a single attribute fails on the top-level entry' do
    it 'formats the message correctly' do
      app_path = File.join(base_dir, 'app')
      Dir.mkdir(app_path)
      FileUtils.chmod(0o700, app_path)

      matcher = be_dir(mode: '0755')
      matcher.matches?(app_path)

      expected_message = <<~MSG.chomp
        #{app_path} was not as expected:
              expected mode to be "0755", but it was "0700"
      MSG
      expect(matcher.failure_message).to eq(expected_message)
    end
  end

  context 'when a single option fails in one nested file' do
    it 'reports the relative path to the file with its failure' do
      app_path = File.join(base_dir, 'app')
      Dir.mkdir(app_path)
      File.write(File.join(app_path, 'config.yml'), 'environment: test')

      matcher = be_dir.containing(
        file('config.yml', content: 'environment: production')
      )
      matcher.matches?(app_path)

      expected_message = <<~MSG.chomp
        #{app_path} was not as expected:
          - config.yml
              expected content to be "environment: production", but it was "environment: test"
      MSG
      expect(matcher.failure_message).to eq(expected_message)
    end
  end

  context 'when multiple attributes fail on the same nested file' do
    it 'groups the failures under a single relative file path' do
      bin_path = File.join(base_dir, 'bin')
      setup_path = File.join(bin_path, 'setup')
      Dir.mkdir(bin_path)
      File.write(setup_path, '#!/bin/sh')
      FileUtils.chmod(0o755, setup_path)
      mock_file_stat(setup_path, uid: 9999, mode: 0o100755)
      mock_user_name(9999, 'testuser')

      matcher = be_dir.containing(
        file('setup', mode: '0644', owner: 'root')
      )
      matcher.matches?(bin_path)

      expected_message = <<~MSG.chomp
        #{bin_path} was not as expected:
          - setup
              expected mode to be "0644", but it was "0755"
              expected owner to be "root", but it was "testuser"
      MSG
      expect(matcher.failure_message).to eq(expected_message)
    end
  end

  context 'when multiple, separate files fail at different nesting levels' do
    let(:version_rb_content) { 'VERSION = "0.1.0"' }

    it 'flattens the report into a simple list of failed files and their reasons' do
      # ... (setup is the same) ...
      bin_dir = File.join(base_dir, 'bin')
      lib_dir = File.join(base_dir, 'lib/new_project')
      setup_path = File.join(bin_dir, 'setup')
      version_path = File.join(lib_dir, 'version.rb')
      FileUtils.mkdir_p(bin_dir)
      FileUtils.mkdir_p(lib_dir)
      File.write(setup_path, '#!/bin/sh')
      File.write(version_path, version_rb_content)
      FileUtils.chmod(0o755, setup_path)

      mock_file_stat(setup_path, uid: 9999, mode: 0o100755)
      mock_user_name(9999, 'owner')

      matcher = be_dir.containing(
        dir('bin').containing(
          file('setup', mode: '0644', owner: 'root')
        ),
        dir('lib').containing(
          dir('new_project').containing(
            file('version.rb', content: include('VERSION = "0.1.1"'))
          )
        )
      )
      matcher.matches?(base_dir)

      expected_message = <<~MSG.chomp
        #{base_dir} was not as expected:
          - bin/setup
              expected mode to be "0644", but it was "0755"
              expected owner to be "root", but it was "owner"
          - lib/new_project/version.rb
              expected content to include "VERSION = \\"0.1.1\\"", but it was #{version_rb_content.inspect}
      MSG
      expect(matcher.failure_message).to eq(expected_message)
    end
  end

  context "when 'containing_exactly' fails due to an unexpected file" do
    it 'reports the failure on the directory itself' do
      dist_path = File.join(base_dir, 'dist')
      Dir.mkdir(dist_path)
      File.write(File.join(dist_path, 'app.js'), '// ...')
      File.write(File.join(dist_path, 'unexpected.log'), 'debug info')

      matcher = be_dir.containing_exactly(
        file('app.js')
      )
      matcher.matches?(dist_path)

      expected_message = <<~MSG.chomp
        #{dist_path} was not as expected:
              expected no other entries, but found ["unexpected.log"]
      MSG
      expect(matcher.failure_message).to eq(expected_message)
    end
  end
end
