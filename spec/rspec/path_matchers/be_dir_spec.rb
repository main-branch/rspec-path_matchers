# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'the be_dir matcher' do
  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  let(:tmpdir) { @tmpdir }
  let(:entry_name) { 'dir' }
  let(:path) { File.join(tmpdir, entry_name) }

  describe 'checking existance' do
    subject { expect(path).to be_dir }

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

      it 'should fail' do
        expected_message = /expected it to be a directory/
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
        target_file = File.join(tmpdir, 'target_file')
        File.write(target_file, 'regular file')
        File.symlink(target_file, path)
      end

      it 'should fail' do
        expected_message = /expected it to be a directory/
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

      it 'should fail' do
        expected_message = /expected it to exist/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end
  end

  describe 'not_to be_dir' do
    subject { expect(path).not_to be_dir }

    context 'when the path does not exist' do
      it 'should not fail' do
        expect { subject }.not_to raise_error
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
        expected_message = /expected it not to be a directory/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the path is a symlink to a regular file' do
      before do
        target_path = File.join(tmpdir, 'target_file.txt')
        File.write(target_path, 'regular file')
        File.symlink(target_path, path)
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
        expected_message = /expected it not to be a directory/
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

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when given other options' do
      subject { expect(path).not_to be_dir(owner: 'user') }

      before { FileUtils.mkdir(path) }

      it 'should fail' do
        expected_message = 'The matcher `not_to be_dir(...)` cannot be given options'
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to include(expected_message)
        end
      end
    end

    context 'when given an expectation on its contents' do
      subject { expect(path).not_to be_dir.containing(file('file1.txt')) }

      before { FileUtils.mkdir(path) }

      it 'should fail' do
        expected_message = 'The matcher `not_to be_dir(...)` cannot have expectations on its contents'
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to include(expected_message)
        end
      end
    end
  end

  context 'when given invalid options' do
    subject { expect(path).to be_dir(**options) }

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

  describe 'the mode: option' do
    before(:all) do
      # :nocov: this line is platform-specific
      skip 'File mode tests are only applicable on Unix-like platforms' unless UNIX_LIKE_PLATFORM
      # :nocov:
    end

    subject { expect(path).to be_dir(mode: expected_mode) }

    before { FileUtils.mkdir(path) }

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
          expected_message = Regexp.escape('expected mode to match /^07..$/, but it was "0600"')
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the owner: option' do
    subject { expect(path).to be_dir(owner: expected_owner) }

    before { FileUtils.mkdir(path) }

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

        FileUtils.touch(path)

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
          FileUtils.touch(path)
          mock_file_stat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          FileUtils.touch(path)
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
    subject { expect(path).to be_dir(group: expected_group) }

    before { FileUtils.mkdir(path) }

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

        FileUtils.touch(path)

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
          FileUtils.touch(path)
          mock_file_stat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          FileUtils.touch(path)
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
    subject { expect(path).to be_dir(atime: expected_atime) }

    before { FileUtils.mkdir(path) }

    context 'when the expected atime is not valid' do
      let(:expected_atime) { 'invalid' }

      it 'should raise an ArgumentError' do
        FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, atime: expected_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, atime: actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, atime: actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
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
    subject { expect(path).to be_dir(birthtime: expected_birthtime) }

    before { FileUtils.mkdir(path) }

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
        FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, birthtime: expected_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, birthtime: actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, birthtime: actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
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
    subject { expect(path).to be_dir(ctime: expected_ctime) }

    before { FileUtils.mkdir(path) }

    context 'when the expected ctime is not valid' do
      let(:expected_ctime) { 'invalid' }

      it 'should raise an ArgumentError' do
        FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, ctime: expected_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, ctime: actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, ctime: actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
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
    subject { expect(path).to be_dir(mtime: expected_mtime) }

    before { FileUtils.mkdir(path) }

    context 'when given an invalid mtime value' do
      let(:expected_mtime) { 'invalid' }

      it 'should raise an ArgumentError' do
        FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
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
          FileUtils.touch(path)
          mock_file_stat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_stat(path, mtime: actual_mtime)
          expected_message = /expected mtime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  context 'when given expectations on its contents' do
    before { FileUtils.mkdir(path) }

    context 'with no expectations' do
      subject do
        expect(path).to(be_dir.containing)
      end

      it 'should not fail' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with an expectation that it contains a file with json content' do
      let(:subject) do
        expect(path).to(
          be_dir.containing(file('file.json', json_content: true))
        )
      end

      context 'when the expectation is met' do
        before do
          File.write(File.join(path, 'file.json'), '{"key": "value"}')
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expectation is not met' do
        before do
          File.write(File.join(path, 'file.json'), 'not a json file')
        end

        it 'should fail' do
          expected_message = /expected valid JSON content, but got error: /
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'with an expectation that it contains a directory' do
      let(:subject) do
        expect(path).to(be_dir.containing(dir('nested_dir')))
      end

      context 'when the expectation is met' do
        before do
          nested_path = File.join(path, 'nested_dir')
          Dir.mkdir(nested_path)
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expectation is not met' do
        it 'should fail' do
          expected_message = /expected it to exist/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'with an expectation that it contains a symlink' do
      let(:subject) do
        expect(path).to(be_dir.containing(symlink('nested_symlink', target: 'expected_target')))
      end

      context 'when the expectation is met' do
        before do
          File.symlink('expected_target', File.join(path, 'nested_symlink'))
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expectation is not met' do
        it 'should fail' do
          expected_message = /expected it to exist/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'with expectations that it contains multiple files' do
      let(:subject) do
        expect(path).to(
          be_dir.containing(
            file('file1.txt', content: 'content1'),
            file('file2.txt', content: 'content2')
          )
        )
      end

      context 'when the expectations are all met' do
        before do
          File.write(File.join(path, 'file1.txt'), 'content1')
          File.write(File.join(path, 'file2.txt'), 'content2')
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expectations are not all met' do
        before do
          File.write(File.join(path, 'file1.txt'), 'wrong content')
        end

        it 'should fail' do
          expected_message = /expected it to exist/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'with deeply nested expectations' do
      let(:subject) do
        expect(path).to(
          be_dir.containing(
            dir('nested_dir').containing(
              file('deeply_nested_file.txt', content: 'content')
            )
          )
        )
      end

      context 'when the expectations are met' do
        before do
          nested_path = File.join(path, 'nested_dir')
          Dir.mkdir(nested_path)
          File.write(File.join(nested_path, 'deeply_nested_file.txt'), 'content')
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expectations are not met' do
        before do
          nested_path = File.join(path, 'nested_dir')
          Dir.mkdir(nested_path)
          File.write(File.join(nested_path, 'deeply_nested_file.txt'), 'unexpected content')
        end

        it 'should fail' do
          expected_message = /expected content to be "content"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  context 'with negative assertions in the specification block' do
    before { FileUtils.mkdir(path) }

    describe 'the no_file_named method' do
      subject do
        expect(path).to(be_dir.containing(no_file_named('entry.txt')))
      end

      context 'when the file does not exist' do
        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when an entry with the same name exists but is a directory' do
        before do
          Dir.mkdir(File.join(path, 'entry.txt'))
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the file exists' do
        before do
          File.write(File.join(path, 'entry.txt'), 'content')
        end

        it 'should fail' do
          expected_message = /expected file 'entry\.txt' not to be found at '.*', but it exists/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    describe 'the no_dir_named method' do
      subject do
        expect(path).to(be_dir.containing(no_dir_named('subdir')))
      end

      context 'when the directory does not exist' do
        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when an entry with the same name exists but is a file' do
        before do
          File.write(File.join(path, 'subdir'), 'content')
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the directory exists' do
        before do
          Dir.mkdir(File.join(path, 'subdir'))
        end

        it 'should fail' do
          expected_message = /expected directory 'subdir' not to be found at '.*', but it exists/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    describe 'the no_symlink_named method' do
      subject do
        expect(path).to(be_dir.containing(no_symlink_named('a_link')))
      end

      context 'when the symlink does not exist' do
        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when an entry with the same name exists but is a file' do
        before do
          File.write(File.join(path, 'a_link'), 'content')
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the symlink exists' do
        before do
          File.symlink('a_target', File.join(path, 'a_link'))
        end

        it 'should fail' do
          expected_message = /expected symlink 'a_link' not to be found at '.*', but it exists/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when mixing positive and negative assertions' do
      subject do
        expect(path).to(be_dir.containing(file('good_file.txt'), no_file_named('bad_file.txt')))
      end

      context 'when all assertions are met' do
        before do
          File.write(File.join(path, 'good_file.txt'), 'content')
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when a positive assertion fails' do
        # 'good_file.txt' is not created
        it 'should fail' do
          expected_message = /expected it to exist/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end

      context 'when a negative assertion fails' do
        before do
          File.write(File.join(path, 'good_file.txt'), 'content')
          File.write(File.join(path, 'bad_file.txt'), 'i should not be here')
        end

        it 'should fail' do
          expected_message = /expected file 'bad_file\.txt' not to be found at '.*', but it exists/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end
end
