# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'the be_file matcher' do
  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  let(:tmpdir) { @tmpdir }
  let(:entry_name) { 'file' }
  let(:path) { File.join(tmpdir, entry_name) }

  describe 'checking existance' do
    subject { expect(path).to be_file }

    context 'when the path does not exist' do
      it 'should fail' do
        expected_message = /expected it to exist/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the path is a regular file' do
      before do
        FileUtils.touch(path)
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the path is a directory' do
      before do
        Dir.mkdir(path)
      end

      it 'should fail' do
        expected_message = /expected it to be a regular file/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the path is a symlink to a regular file' do
      before do
        target_file = File.join(tmpdir, 'target_file')
        File.write(target_file, 'regular file')
        File.symlink(target_file, path)
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the path is a symlink to a directory' do
      before do
        target_path = File.join(tmpdir, 'target_dir')
        Dir.mkdir(target_path)
        File.symlink(target_path, path)
      end

      it 'should fail' do
        expected_message = /expected it to be a regular file/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the path is a dangling symlink' do
      before do
        target_path = File.join(tmpdir, 'target.txt')
        File.symlink(target_path, File.join(tmpdir, 'link.txt'))
      end

      it 'should fail' do
        expected_message = /expected it to exist/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end
  end

  describe 'not_to have_file' do
    subject { expect(path).not_to be_file }

    context 'when the path does not exist' do
      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the path is a regular file' do
      before do
        FileUtils.touch(path)
      end

      it 'should fail' do
        expected_message = /expected it not to be a file/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the path is a directory' do
      before do
        Dir.mkdir(path)
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the path is a symlink to a regular file' do
      before do
        target_path = File.join(tmpdir, 'target_file.txt')
        File.write(target_path, 'regular file')
        File.symlink(target_path, path)
      end

      it 'should fail' do
        expected_message = /expected it not to be a file/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the path is a symlink to a directory' do
      before do
        target_path = File.join(tmpdir, 'target_dir')
        Dir.mkdir(target_path)
        File.symlink(target_path, path)
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the path is a dangling symlink' do
      before do
        target_path = File.join(tmpdir, 'target.txt')
        File.symlink(target_path, File.join(tmpdir, 'link.txt'))
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when given other options' do
      subject { expect(path).not_to be_file(owner: 'user') }

      before { FileUtils.touch(path) }

      it 'should fail' do
        expected_message = 'The matcher `not_to be_file(...)` cannot be given options'
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to include(expected_message)
        end
      end
    end
  end

  context 'when given invalid options' do
    before { FileUtils.touch(path) }

    subject { expect(path).to be_file(**options) }

    context 'with an invalid option' do
      let(:options) { { invalid_option: true } }
      it 'should raise an ArgumentError' do
        expected_message = /unknown keyword: :invalid_option/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'with more than one invalid option' do
      let(:options) { { invalid_option: true, another_invalid: false } }
      it 'should raise an ArgumentError listing all invalid options' do
        expected_message = /unknown keywords: :invalid_option, :another_invalid/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end
  end

  describe 'the content: option' do
    subject { expect(path).to be_file(content: expected_content) }

    before do
      if defined?(actual_content)
        File.write(path, actual_content)
      else
        FileUtils.touch(path)
      end
    end

    context 'when the expected content is not valid' do
      let(:expected_content) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `content:` to be a Matcher, String, or Regexp, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the expected content is valid' do
      context 'when the expected content is a String' do
        let(:expected_content) { 'Hello, World!' }

        context 'when the expected content matches the actual content' do
          let(:actual_content) { expected_content }

          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the expected content does not match the actual content' do
          let(:actual_content) { 'Goodbye, World!' }

          it 'should fail' do
            expected_message = /expected content to be "#{expected_content}", but it was "Goodbye, World!"/
            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to match(expected_message)
            end
          end

          context 'when the actual content is long' do
            let(:actual_content) { 'a' * 1000 }

            it 'should not include the actual content in the error message' do
              expected_message = /expected content to be "Hello, World!", but it was not/
              expect { subject }.to raise_error(expectation_not_met_error) do |error|
                expect(error.message).to match(expected_message)
              end
            end
          end
        end
      end

      context 'the expected content is a Regexp' do
        let(:expected_content) { /Hello/ }

        context 'when the expected content matches the actual content' do
          let(:actual_content) { 'Hello, World!' }

          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the expected content does not match the actual content' do
          let(:actual_content) { 'Goodbye, World!' }

          it 'should fail' do
            expected_message = %r{expected content to match /Hello/}
            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to match(expected_message)
            end
          end

          context 'when the actual content is long' do
            let(:actual_content) { 'a' * 1000 }

            it 'should not include the actual content in the error message' do
              expected_message = %r{expected content to match /Hello/, but it did not}
              expect { subject }.to raise_error(expectation_not_met_error) do |error|
                expect(error.message).to match(expected_message)
              end
            end
          end
        end
      end

      context 'when the expected content is a matcher' do
        let(:expected_content) { include('Hello') }

        context 'when the expected content matches the actual content' do
          let(:actual_content) { 'Hello, World!' }

          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the expected content does not match the actual content' do
          let(:actual_content) { 'Goodbye, World!' }

          it 'should fail' do
            expected_message = /expected content to include "Hello", but it was "Goodbye, World!"/
            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to match(expected_message)
            end
          end

          context 'when the actual content is long' do
            let(:actual_content) { 'a' * 1000 }

            it 'should not include the actual content in the error message' do
              expected_message = /expected content to include "Hello", but it did not/
              expect { subject }.to raise_error(expectation_not_met_error) do |error|
                expect(error.message).to match(expected_message)
              end
            end
          end
        end
      end
    end
  end

  describe 'the json_content: option' do
    subject { expect(path).to be_file(json_content: expected_content) }

    before do
      if defined?(actual_content)
        File.write(path, actual_content)
      else
        FileUtils.touch(path)
      end
    end

    context 'when the expected content is not valid' do
      let(:expected_content) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `json_content:` to be a Matcher or TrueClass, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the expected content is true' do
      let(:expected_content) { true }

      context 'when the actual content is valid JSON' do
        let(:actual_content) { '{"key": "value"}' }

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the actual content is not valid JSON' do
        let(:actual_content) { 'not a json' }

        it 'should fail' do
          expected_message = /expected valid JSON content, but got error/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when the expected content is a matcher' do
      let(:expected_content) { include('key' => 'value') }

      context 'when the expected content matches the actual content' do
        let(:actual_content) { '{"key": "value"}' }

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected content does not match the actual content' do
        let(:actual_content) { '{"key": "different_value"}' }

        it 'should fail' do
          expected_message = /expected JSON content to include /
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end

        context 'when the actual content is long' do
          let(:actual_content) { %({"key": "#{'a' * 1000}"}) }

          it 'should not include the actual content in the error message' do
            expected_message = <<~MESSAGE.chomp
              #{path} was not as expected:
                    expected JSON content to include {"key" => "value"}, but it did not
            MESSAGE

            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to eq(expected_message)
            end
          end
        end
      end
    end
  end

  describe 'the yaml_content: option' do
    subject { expect(path).to be_file(yaml_content: expected_content) }

    before do
      if defined?(actual_content)
        File.write(path, actual_content)
      else
        FileUtils.touch(path)
      end
    end

    context 'when the expected content is not valid' do
      let(:expected_content) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `yaml_content:` to be a Matcher or TrueClass, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when yaml_content is true' do
      let(:expected_content) { true }

      context 'when the actual content is valid YAML' do
        let(:actual_content) { "key: value\nanother_key: another_value" }

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the actual content is not valid YAML' do
        let(:actual_content) { "\tnot a yaml" }

        it 'should fail' do
          expected_message = /expected valid YAML content, but got error/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_content) { include('key' => 'value') }

      context 'when the actual content is not valid YAML' do
        let(:actual_content) { "\tnot a yaml" }

        it 'should fail' do
          expected_message = /expected valid YAML content, but got error/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end

      context 'when the expected content matches the actual content' do
        let(:actual_content) { <<~YAML }
          key: value
          another_key: another_value
        YAML

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected content does not match the actual content' do
        let(:actual_content) { <<~YAML }
          key: different_value
          another_key: another_value
        YAML

        it 'should fail' do
          expected_message = /expected YAML content to include/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end

        context 'when the actual content is long' do
          let(:actual_content) { %(key: "#{'a' * 1000}") }

          it 'should not include the actual content in the error message' do
            expected_message = <<~MESSAGE.chomp
              #{path} was not as expected:
                    expected YAML content to include {"key" => "value"}, but it did not
            MESSAGE

            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to eq(expected_message)
            end
          end
        end
      end
    end
  end

  describe 'the size: option' do
    subject { expect(path).to be_file(size: expected_size) }

    before { FileUtils.touch(path) }

    context 'when given an invalid size value' do
      let(:expected_size) { 'invalid' }
      it 'should raise an ArgumentError' do
        expected_message = /expected `size:` to be a Matcher or Integer, but it was "invalid"/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when given an Integer' do
      let(:expected_size) { 13 }

      context 'when the expected size matches the actual size' do
        it 'should not fail' do
          File.write(path, 'Hello, World!')
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected size does not match the actual size' do
        it 'should fail' do
          File.write(path, 'Short')
          expected_message = /expected size to be 13, but it was 5/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_size) { be > 10 }

      context 'when the expected size matches the actual size' do
        it 'should not fail' do
          File.write(path, 'Hello, World!')
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected size does not match the actual size' do
        it 'should fail' do
          File.write(path, 'Short')
          expected_message = /expected size to be > 10, but it was 5/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the mode: option' do
    subject { expect(path).to be_file(mode: expected_mode) }

    before { FileUtils.touch(path) }

    context 'when the expected value is not valid' do
      let(:expected_mode) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `mode:` to be a Matcher or String, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when given a String' do
      let(:expected_mode) { '0644' }

      context 'when the expected mode matches the actual mode' do
        let(:actual_mode) { expected_mode }
        it 'should not fail' do
          FileUtils.chmod(expected_mode.to_i(8), path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mode does not match the actual mode' do
        let(:actual_mode) { '0755' }
        it 'should fail' do
          FileUtils.chmod(actual_mode.to_i(8), path)
          expected_message = /expected mode to be "0644", but it was "0755"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_mode) { match(/^07..$/) }

      context 'when the expected mode matches the actual mode' do
        let(:actual_mode) { '0755' }

        it 'should not fail' do
          FileUtils.chmod(actual_mode.to_i(8), path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mode does not match the actual mode' do
        let(:actual_mode) { '0600' }
        it 'should fail' do
          FileUtils.chmod(actual_mode.to_i(8), path)
          expected_message = Regexp.escape('expected mode to match /^07..$/, but it was "0600"')
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the owner: option' do
    subject { expect(path).to be_file(owner: expected_owner) }

    before { FileUtils.touch(path) }

    context 'when the expected owner is not valid' do
      let(:expected_owner) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `owner:` to be a Matcher or String, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the platform does not support owner expectations' do
      let(:expected_owner) { 'testuser' }

      it 'should give a warning and not check the owner' do
        allow(Etc).to receive(:respond_to?).and_call_original
        allow(Etc).to receive(:respond_to?).with(:getpwuid).and_return(false)

        expect(RSpec.configuration.reporter).to receive(:message).with(
          'WARNING: owner expectations are not supported on this platform and will be skipped.'
        )

        expect { subject }.not_to raise_error
      end
    end

    context 'when given a String' do
      let(:expected_owner) { 'testuser' }

      context 'when the expected owner matches the actual owner' do
        let(:actual_owner) { expected_owner }

        it 'should not fail' do
          mock_file_stat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          mock_file_stat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expected_message = /expected owner to be "testuser", but it was "otheruser"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_owner) { eq 'testuser' }

      context 'when the expected owner matches the actual owner' do
        let(:actual_owner) { 'testuser' }

        it 'should not fail' do
          mock_file_stat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          mock_file_stat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expected_message = /expected owner to eq "testuser", but it was "otheruser"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the group: option' do
    subject { expect(path).to be_file(group: expected_group) }

    before { FileUtils.touch(path) }

    context 'when given an invalid group value' do
      let(:expected_group) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `group:` to be a Matcher or String, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the platform does not support group expectations' do
      let(:expected_group) { 'testgroup' }

      it 'should give a warning and not check the group' do
        allow(Etc).to receive(:respond_to?).and_call_original
        allow(Etc).to receive(:respond_to?).with(:getgrgid).and_return(false)

        expect(RSpec.configuration.reporter).to receive(:message).with(
          'WARNING: group expectations are not supported on this platform and will be skipped.'
        )

        expect { subject }.not_to raise_error
      end
    end

    context 'when given a String' do
      let(:expected_group) { 'testgroup' }

      context 'when the expected group matches the actual group' do
        let(:actual_group) { expected_group }

        it 'should not fail' do
          mock_file_stat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          mock_file_stat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expected_message = /expected group to be "testgroup", but it was "othergroup"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_group) { eq 'testgroup' }

      context 'when the expected group matches the actual group' do
        let(:actual_group) { 'testgroup' }

        it 'should not fail' do
          mock_file_stat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          mock_file_stat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expected_message = /expected group to eq "testgroup", but it was "othergroup"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the atime: option' do
    subject { expect(path).to be_file(atime: expected_atime) }

    before { FileUtils.touch(path) }

    context 'when the expected atime is not valid' do
      let(:expected_atime) { 'invalid' }

      it 'should raise an ArgumentError' do
        expected_message = /expected `atime:` to be a Matcher, Time, or DateTime, but it was "invalid"/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when expected atime is a Time' do
      let(:expected_atime) { mocked_now }

      context 'when the expected atime matches the actual atime' do
        let(:actual_atime) { mocked_now }

        it 'should not fail' do
          mock_file_stat(path, atime: expected_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, atime: actual_atime)
          expected_message = /expected atime to be #{expected_atime.inspect}, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when the expected atime is a DateTime' do
      let(:expected_atime) { mocked_now.to_datetime }

      context 'when the expected atime matches the actual atime' do
        let(:actual_atime) { mocked_now }

        it 'should not fail' do
          mock_file_stat(path, atime: actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, atime: actual_atime)
          expected_message = /expected atime to be 1967-03-15 00:16:00 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when the expected atime is a matcher' do
      let(:expected_atime) { be_within(10).of(mocked_now) }

      context 'when the expected atime matches the actual atime' do
        let(:actual_atime) { mocked_now - 5 }

        it 'should not fail' do
          mock_file_stat(path, atime: actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now - 20 }

        it 'should fail' do
          mock_file_stat(path, atime: actual_atime)
          expected_message = /expected atime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the birthtime: option' do
    subject { expect(path).to be_file(birthtime: expected_birthtime) }

    before { FileUtils.touch(path) }

    context 'for a path that does not support birthtime' do
      let(:expected_birthtime) { mocked_now }

      before do
        allow_any_instance_of(File::Stat).to receive(:birthtime).and_raise(NotImplementedError)
      end

      it 'should give a warning and skip the birthtime check' do
        expected_message = "WARNING: birthtime expectations are not supported for #{path} and will be skipped"
        expect(RSpec.configuration.reporter).to receive(:message).with(expected_message)
        expect { subject }.not_to raise_error
      end
    end

    context 'when the expected birthtime is not valid' do
      let(:expected_birthtime) { 'invalid' }

      it 'should raise an ArgumentError' do
        expected_message = /expected `birthtime:` to be a Matcher, Time, or DateTime, but it was "invalid"/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when expected birthtime is a Time' do
      let(:expected_birthtime) { mocked_now }

      context 'when the expected birthtime matches the actual birthtime' do
        let(:actual_birthtime) { mocked_now }

        it 'should not fail' do
          mock_file_stat(path, birthtime: expected_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, birthtime: actual_birthtime)
          expected_message = /expected birthtime to be #{expected_birthtime.inspect}, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when the expected birthtime is a DateTime' do
      let(:expected_birthtime) { mocked_now.to_datetime }

      context 'when the expected birthtime matches the actual birthtime' do
        let(:actual_birthtime) { mocked_now }

        it 'should not fail' do
          mock_file_stat(path, birthtime: actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, birthtime: actual_birthtime)
          expected_message = /expected birthtime to be 1967-03-15 00:16:00 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when the expected birthtime is a matcher' do
      let(:expected_birthtime) { be_within(10).of(mocked_now) }

      context 'when the expected birthtime matches the actual birthtime' do
        let(:actual_birthtime) { mocked_now - 5 }

        it 'should not fail' do
          mock_file_stat(path, birthtime: actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now - 20 }

        it 'should fail' do
          mock_file_stat(path, birthtime: actual_birthtime)
          expected_message = /expected birthtime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the ctime: option' do
    subject { expect(path).to be_file(ctime: expected_ctime) }

    before { FileUtils.touch(path) }

    context 'when the expected ctime is not valid' do
      let(:expected_ctime) { 'invalid' }

      it 'should raise an ArgumentError' do
        expected_message = /expected `ctime:` to be a Matcher, Time, or DateTime, but it was "invalid"/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when expected ctime is a Time' do
      let(:expected_ctime) { mocked_now }

      context 'when the expected ctime matches the actual ctime' do
        let(:actual_ctime) { mocked_now }

        it 'should not fail' do
          mock_file_stat(path, ctime: expected_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, ctime: actual_ctime)
          expected_message = /expected ctime to be #{expected_ctime.inspect}, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when the expected ctime is a DateTime' do
      let(:expected_ctime) { mocked_now.to_datetime }

      context 'when the expected ctime matches the actual ctime' do
        let(:actual_ctime) { mocked_now }

        it 'should not fail' do
          mock_file_stat(path, ctime: actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, ctime: actual_ctime)
          expected_message = /expected ctime to be 1967-03-15 00:16:00 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when the expected ctime is a matcher' do
      let(:expected_ctime) { be_within(10).of(mocked_now) }

      context 'when the expected ctime matches the actual ctime' do
        let(:actual_ctime) { mocked_now - 5 }

        it 'should not fail' do
          mock_file_stat(path, ctime: actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now - 20 }

        it 'should fail' do
          mock_file_stat(path, ctime: actual_ctime)
          expected_message = /expected ctime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the mtime: option' do
    subject { expect(path).to be_file(mtime: expected_mtime) }

    before { FileUtils.touch(path) }

    context 'when given an invalid mtime value' do
      let(:expected_mtime) { 'invalid' }

      it 'should raise an ArgumentError' do
        expected_message = /expected `mtime:` to be a Matcher, Time, or DateTime, but it was "invalid"/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when given a Time' do
      let(:expected_mtime) { mocked_now }

      context 'when the expected mtime matches the actual mtime' do
        let(:actual_mtime) { expected_mtime }

        it 'should not fail' do
          mock_file_stat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, mtime: actual_mtime)

          expected_message = /expected mtime to be #{expected_mtime.inspect}, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a DateTime' do
      let(:expected_mtime) { mocked_now.to_datetime }

      context 'when the expected mtime matches the actual mtime' do
        let(:actual_mtime) { mocked_now }

        it 'should not fail' do
          mock_file_stat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now + 10 }

        it 'should fail' do
          mock_file_stat(path, mtime: actual_mtime)
          expected_message = /expected mtime to be 1967-03-15 00:16:00 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_mtime) { be_within(10).of(mocked_now) }

      context 'when the expected mtime matches the actual mtime' do
        let(:actual_mtime) { mocked_now - 5 }

        it 'should not fail' do
          mock_file_stat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now - 20 }

        it 'should fail' do
          mock_file_stat(path, mtime: actual_mtime)
          expected_message = /expected mtime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end
end
