# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'the have_file matcher' do
  let(:now) { Time.new(1967, 3, 15, 0, 16, 0, '-0700') }

  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  let(:tmpdir) { @tmpdir }
  let(:expected_name) { 'file.txt' }
  let(:path) { File.join(tmpdir, expected_name) }

  let(:expectation_not_met_error) { RSpec::Expectations::ExpectationNotMetError }

  before do
    if defined?(actual_content)
      File.write(path, actual_content)
    else
      FileUtils.touch(path)
    end
  end

  describe 'checking existance' do
    subject { expect(tmpdir).to have_file(expected_name) }

    context 'when the entry at the given path is a regular file' do
      before do
        FileUtils.touch(File.join(tmpdir, expected_name))
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the entry at the given path does not exist' do
      before do
        FileUtils.rm(path)
      end

      it 'should fail' do
        expected_message = /expected it to exist/
        expect { subject }.to raise_error(expectation_not_met_error, expected_message)
      end
    end

    context 'when the entry at the given path is not a regular file' do
      before do
        FileUtils.rm(path)
        Dir.mkdir(File.join(tmpdir, expected_name))
      end

      it 'should fail' do
        expected_message = /expected it to be a regular file/
        expect { subject }.to raise_error(expectation_not_met_error, expected_message)
      end
    end

    context 'when the entry at the given path is a symlink to a regular file' do
      before do
        FileUtils.rm(path)
        FileUtils.touch(File.join(tmpdir, 'target.txt'))
        File.symlink('target.txt', File.join(tmpdir, expected_name))
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the entry at the given path is a symlink to a directory' do
      before do
        FileUtils.rm(path)
        Dir.mkdir(File.join(tmpdir, 'target.dir'))
        File.symlink('target.dir', File.join(tmpdir, expected_name))
      end

      it 'should fail' do
        expected_message = /expected it to be a regular file/
        expect { subject }.to raise_error(expectation_not_met_error, expected_message)
      end
    end

    context 'when the entry at the given path is a dangling symlink' do
      before do
        FileUtils.rm(path)
        FileUtils.touch(File.join(tmpdir, 'target.txt'))
        File.symlink('target.txt', File.join(tmpdir, 'link.txt'))
        FileUtils.rm(File.join(tmpdir, 'target.txt')) # Remove the target file
      end

      it 'should fail' do
        expected_message = /expected it to exist/
        expect { subject }.to raise_error(expectation_not_met_error, expected_message)
      end
    end
  end

  context 'when given invalid options' do
    before do
      FileUtils.touch(File.join(tmpdir, expected_name))
    end

    subject { expect(tmpdir).to have_file(expected_name, **options) }

    context 'with an invalid option' do
      let(:options) { { invalid_option: true } }
      it 'should raise an ArgumentError' do
        expected_message = /unknown keyword: :invalid_option/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'with more than one invalid option' do
      let(:options) { { invalid_option: true, another_invalid: false } }
      it 'should raise an ArgumentError listing all invalid options' do
        expected_message = /unknown keywords: :invalid_option, :another_invalid/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end
  end

  describe 'the content: option' do
    subject { expect(tmpdir).to have_file(expected_name, content: expected_content) }

    let(:path) { File.join(tmpdir, expected_name) }

    context 'when the expected content is not valid' do
      let(:expected_content) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `content:` to be a String, Regexp, or Matcher, but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
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
            expected_message = /expected content to be "#{expected_content}"/
            expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
            expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
            expected_message = /expected content to include "Hello"/
            expect { subject }.to raise_error(expectation_not_met_error, expected_message)
          end
        end
      end
    end
  end

  describe 'the json_content: option' do
    subject { expect(tmpdir).to have_file(expected_name, json_content: expected_content) }

    let(:path) { File.join(tmpdir, expected_name) }

    context 'when the expected content is not valid' do
      let(:expected_content) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `json_content:` to be a Matcher or true, but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
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
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the yaml_content: option' do
    subject { expect(tmpdir).to have_file(expected_name, yaml_content: expected_content) }

    let(:path) { File.join(tmpdir, expected_name) }

    context 'when the expected content is not valid' do
      let(:expected_content) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `yaml_content:` to be a Matcher or true, but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
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
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_content) { include('key' => 'value') }

      context 'when the actual content is not valid YAML' do
        let(:actual_content) { "\tnot a yaml" }

        it 'should fail' do
          expected_message = /expected valid YAML content, but got error/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the size: option' do
    subject { expect(tmpdir).to have_file(expected_name, size: expected_size) }

    let(:path) { File.join(tmpdir, expected_name) }

    context 'when given an invalid size value' do
      let(:expected_size) { 'invalid' }
      it 'should raise an ArgumentError' do
        expected_message = /expected `size:` to be a Matcher or an Integer, but was "invalid"/
        expect { subject }.to raise_error(ArgumentError, expected_message)
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
          expected_message = /expected size to be 13, but was 5/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expected_message = /expected size to be > 10, but was 5/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the mode: option' do
    subject { expect(tmpdir).to have_file(expected_name, mode: expected_mode) }

    let(:path) { File.join(tmpdir, expected_name) }

    context 'when the expected value is not valid' do
      let(:expected_mode) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `mode:` to be a Matcher or a String, but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when given a String' do
      let(:expected_mode) { '0644' }

      context 'when the expected mode matches the actual mode' do
        let(:actual_mode) { expected_mode }
        it 'should not fail' do
          FileUtils.touch(path)
          FileUtils.chmod(expected_mode.to_i(8), path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mode does not match the actual mode' do
        let(:actual_mode) { '0755' }
        it 'should fail' do
          FileUtils.touch(path)
          FileUtils.chmod(actual_mode.to_i(8), path)
          expected_message = /expected mode to be "0644", but was "0755"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_mode) { match(/^07..$/) }

      context 'when the expected mode matches the actual mode' do
        let(:actual_mode) { '0755' }

        it 'should not fail' do
          FileUtils.touch(path)
          FileUtils.chmod(actual_mode.to_i(8), path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mode does not match the actual mode' do
        let(:actual_mode) { '0600' }
        it 'should fail' do
          FileUtils.touch(path)
          FileUtils.chmod(actual_mode.to_i(8), path)
          expected_message = Regexp.escape('expected mode to match /^07..$/, but was "0600"')
          expect { subject }.to raise_error(expectation_not_met_error, /#{expected_message}/)
        end
      end
    end
  end

  describe 'the owner: option' do
    subject { expect(tmpdir).to have_file(expected_name, owner: expected_owner) }

    let(:path) { File.join(tmpdir, expected_name) }

    def mock_owner(path, actual_owner)
      uid = 9999
      allow(File).to receive(:stat).with(path).and_return(double(uid: uid))
      allow(Etc).to receive(:getpwuid).and_return(double(name: actual_owner))
    end

    context 'when the expected owner is not valid' do
      let(:expected_owner) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `owner:` to be a Matcher or a String, but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when the platform does not support owner expectations' do
      let(:expected_owner) { 'testuser' }

      it 'should give a warning and not check the owner' do
        allow(Etc).to receive(:respond_to?).and_call_original
        allow(Etc).to receive(:respond_to?).with(:getpwuid).and_return(false)

        FileUtils.touch(path)

        expect(RSpec.configuration.reporter).to receive(:message).with(
          'WARNING: Owner expectations are not supported on this platform and will be skipped.'
        )

        expect { subject }.not_to raise_error
      end
    end

    context 'when given a String' do
      let(:expected_owner) { 'testuser' }

      context 'when the expected owner matches the actual owner' do
        let(:actual_owner) { expected_owner }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_owner(path, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_owner(path, actual_owner)
          expected_message = /expected owner to be "testuser", but was "otheruser"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_owner) { eq 'testuser' }

      context 'when the expected owner matches the actual owner' do
        let(:actual_owner) { 'testuser' }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_owner(path, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_owner(path, actual_owner)
          expected_message = /expected owner to eq "testuser", but was "otheruser"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the group: option' do
    subject { expect(tmpdir).to have_file(expected_name, group: expected_group) }

    let(:path) { File.join(tmpdir, expected_name) }

    # Etc.getgrgid(File.stat(path).gid).name
    def mock_group(path, name)
      gid = 9999
      allow(File).to receive(:stat).with(path).and_return(double(gid:))
      allow(Etc).to receive(:getgrgid).with(gid).and_return(double(name:))
    end

    context 'when given an invalid group value' do
      let(:expected_group) { 123 }
      it 'should raise an ArgumentError' do
        expected_message = /expected `group:` to be a Matcher or a String, but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when the platform does not support group expectations' do
      let(:expected_group) { 'testgroup' }

      it 'should give a warning and not check the group' do
        allow(Etc).to receive(:respond_to?).and_call_original
        allow(Etc).to receive(:respond_to?).with(:getgrgid).and_return(false)

        FileUtils.touch(path)

        expect(RSpec.configuration.reporter).to receive(:message).with(
          'WARNING: Group expectations are not supported on this platform and will be skipped.'
        )

        expect { subject }.not_to raise_error
      end
    end

    context 'when given a String' do
      let(:expected_group) { 'testgroup' }

      context 'when the expected group matches the actual group' do
        let(:actual_group) { expected_group }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_group(path, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_group(path, actual_group)
          expected_message = /expected group to be "testgroup", but was "othergroup"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_group) { eq 'testgroup' }

      context 'when the expected group matches the actual group' do
        let(:actual_group) { 'testgroup' }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_group(path, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_group(path, actual_group)
          expected_message = /expected group to eq "testgroup", but was "othergroup"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the atime: option' do
    subject { expect(tmpdir).to have_file(expected_name, atime: expected_atime) }

    let(:path) { File.join(tmpdir, expected_name) }

    def mock_atime(path, actual_atime)
      allow(File).to receive(:stat).with(path).and_return(double(atime: actual_atime))
    end

    context 'when the atime option is not supported' do
      it 'should give a warning and not check the atime'
    end

    context 'when the expected atime is not valid' do
      let(:expected_atime) { 'invalid' }

      it 'should raise an ArgumentError' do
        FileUtils.touch(path)
        expected_message = /expected `atime:` to be a Matcher, Time, or DateTime, but was "invalid"/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when expected atime is a Time' do
      let(:expected_atime) { now }

      context 'when the expected atime matches the actual atime' do
        let(:actual_atime) { now }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_atime(path, expected_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_atime(path, actual_atime)
          expected_message = /expected atime to be #{expected_atime.inspect}, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when the expected atime is a DateTime' do
      let(:expected_atime) { now.to_datetime }

      context 'when the expected atime matches the actual atime' do
        let(:actual_atime) { now }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_atime(path, actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_atime(path, actual_atime)
          expected_message = /expected atime to be 1967-03-15 00:16:00 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when the expected atime is a matcher' do
      let(:expected_atime) { be_within(10).of(now) }

      context 'when the expected atime matches the actual atime' do
        let(:actual_atime) { now - 5 }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_atime(path, actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_atime(path, actual_atime)
          expected_message = /expected atime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the birthtime: option' do
    subject { expect(tmpdir).to have_file(expected_name, birthtime: expected_birthtime) }

    let(:path) { File.join(tmpdir, expected_name) }

    def mock_birthtime(path, actual_birthtime)
      allow(File).to receive(:stat).with(path).and_return(double(birthtime: actual_birthtime))
    end

    context 'for a path that does not support birthtime' do
      let(:expected_birthtime) { now }

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
        FileUtils.touch(path)
        expected_message = /expected `birthtime:` to be a Matcher, Time, or DateTime, but was "invalid"/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when expected birthtime is a Time' do
      let(:expected_birthtime) { now }

      context 'when the expected birthtime matches the actual birthtime' do
        let(:actual_birthtime) { now }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_birthtime(path, expected_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_birthtime(path, actual_birthtime)
          expected_message = /expected birthtime to be #{expected_birthtime.inspect}, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when the expected birthtime is a DateTime' do
      let(:expected_birthtime) { now.to_datetime }

      context 'when the expected birthtime matches the actual birthtime' do
        let(:actual_birthtime) { now }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_birthtime(path, actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_birthtime(path, actual_birthtime)
          expected_messsage = /expected birthtime to be 1967-03-15 00:16:00 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_messsage)
        end
      end
    end

    context 'when the expected birthtime is a matcher' do
      let(:expected_birthtime) { be_within(10).of(now) }

      context 'when the expected birthtime matches the actual birthtime' do
        let(:actual_birthtime) { now - 5 }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_birthtime(path, actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_birthtime(path, actual_birthtime)
          expected_message = /expected birthtime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the ctime: option' do
    subject { expect(tmpdir).to have_file(expected_name, ctime: expected_ctime) }

    let(:path) { File.join(tmpdir, expected_name) }

    def mock_ctime(path, actual_ctime)
      allow(File).to receive(:stat).with(path).and_return(double(ctime: actual_ctime))
    end

    context 'when the ctime option is not supported' do
      it 'should give a warning and not check the ctime'
    end

    context 'when the expected ctime is not valid' do
      let(:expected_ctime) { 'invalid' }

      it 'should raise an ArgumentError' do
        FileUtils.touch(path)
        expected_message = /expected `ctime:` to be a Matcher, Time, or DateTime, but was "invalid"/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when expected ctime is a Time' do
      let(:expected_ctime) { now }

      context 'when the expected ctime matches the actual ctime' do
        let(:actual_ctime) { now }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_ctime(path, expected_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_ctime(path, actual_ctime)
          expected_message = /expected ctime to be #{expected_ctime.inspect}, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when the expected ctime is a DateTime' do
      let(:expected_ctime) { now.to_datetime }

      context 'when the expected ctime matches the actual ctime' do
        let(:actual_ctime) { now }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_ctime(path, actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_ctime(path, actual_ctime)
          expected_message = /expected ctime to be 1967-03-15 00:16:00 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when the expected ctime is a matcher' do
      let(:expected_ctime) { be_within(10).of(now) }

      context 'when the expected ctime matches the actual ctime' do
        let(:actual_ctime) { now - 5 }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_ctime(path, actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_ctime(path, actual_ctime)
          expected_message = /expected ctime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the mtime: option' do
    subject { expect(tmpdir).to have_file(expected_name, mtime: expected_mtime) }

    let(:path) { File.join(tmpdir, expected_name) }

    def mock_mtime(path, actual_mtime)
      allow(File).to receive(:stat).with(path).and_return(double(mtime: actual_mtime))
    end

    context 'when the mtime option is not supported' do
      it 'should give a warning and not check the mtime'
    end

    context 'when given an invalid mtime value' do
      let(:expected_mtime) { 'invalid' }

      it 'should raise an ArgumentError' do
        FileUtils.touch(path)
        expected_message = /expected `mtime:` to be a Matcher, Time, or DateTime, but was "invalid"/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when given a Time' do
      let(:expected_mtime) { now }

      context 'when the expected mtime matches the actual mtime' do
        let(:actual_mtime) { expected_mtime }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_mtime(path, actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_mtime(path, actual_mtime)

          expected_message = /expected mtime to be #{expected_mtime.inspect}, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'when given a DateTime' do
      let(:expected_mtime) { now.to_datetime }

      context 'when the expected mtime matches the actual mtime' do
        let(:actual_mtime) { now }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_mtime(path, actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_mtime(path, actual_mtime)
          expected_name = /expected mtime to be 1967-03-15 00:16:00 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_name)
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_mtime) { be_within(10).of(now) }

      context 'when the expected mtime matches the actual mtime' do
        let(:actual_mtime) { now - 5 }

        it 'should not fail' do
          FileUtils.touch(path)
          mock_mtime(path, actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_mtime(path, actual_mtime)
          expected_message = /expected mtime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but was/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end
end
