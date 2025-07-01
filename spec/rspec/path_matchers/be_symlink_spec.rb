# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'the be_symlink matcher' do
  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  let(:tmpdir) { @tmpdir }
  let(:entry_name) { 'symlink' }
  let(:path) { File.join(tmpdir, entry_name) }
  let(:target_path) { File.join(tmpdir, 'target') }

  describe 'checking existance' do
    subject { expect(path).to be_symlink }

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
        expected_message = /expected it to be a symlink/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the path is a directory' do
      before do
        Dir.mkdir(path)
      end

      it 'should fail' do
        expected_message = /expected it to be a symlink/
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

  describe 'not_to be_symlink' do
    subject { expect(path).not_to be_symlink }

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
        expected_message = /expected it not to be a symlink/
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

      it 'should fail' do
        expected_message = /expected it not to be a symlink/
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
      subject { expect(path).not_to be_symlink(owner: 'user') }

      before { File.symlink(target_path, path) }

      it 'should fail' do
        expected_message = 'The matcher `not_to be_symlink(...)` cannot be given options'
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to include(expected_message)
        end
      end
    end
  end

  context 'when given invalid options' do
    before { File.symlink(target_path, path) }

    subject { expect(path).to be_symlink(**options) }

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

  describe 'the owner: option' do
    subject { expect(path).to be_symlink(owner: expected_owner) }

    before { File.symlink(target_path, path) }

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
          mock_file_lstat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, uid: 9999)
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
          mock_file_lstat(path, uid: 9999)
          mock_user_name(9999, actual_owner)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected owner does not match the actual owner' do
        let(:actual_owner) { 'otheruser' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, uid: 9999)
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
    subject { expect(path).to be_symlink(group: expected_group) }

    before { File.symlink(target_path, path) }

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
          mock_file_lstat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, gid: 9999)
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
          mock_file_lstat(path, gid: 9999)
          mock_group_name(9999, actual_group)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected group does not match the actual group' do
        let(:actual_group) { 'othergroup' }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, gid: 9999)
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
    subject { expect(path).to be_symlink(atime: expected_atime) }

    before { File.symlink(target_path, path) }

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
          mock_file_lstat(path, atime: expected_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, atime: actual_atime)
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
          mock_file_lstat(path, atime: actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, atime: actual_atime)
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
          mock_file_lstat(path, atime: actual_atime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected atime does not match the actual atime' do
        let(:actual_atime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, atime: actual_atime)
          expected_message = /expected atime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the birthtime: option' do
    subject { expect(path).to be_symlink(birthtime: expected_birthtime) }

    before { File.symlink(target_path, path) }

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
          mock_file_lstat(path, birthtime: expected_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, birthtime: actual_birthtime)
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
          mock_file_lstat(path, birthtime: actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, birthtime: actual_birthtime)
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
          mock_file_lstat(path, birthtime: actual_birthtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected birthtime does not match the actual birthtime' do
        let(:actual_birthtime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, birthtime: actual_birthtime)
          expected_message = /expected birthtime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the ctime: option' do
    subject { expect(path).to be_symlink(ctime: expected_ctime) }

    before { File.symlink(target_path, path) }

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
          mock_file_lstat(path, ctime: expected_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, ctime: actual_ctime)
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
          mock_file_lstat(path, ctime: actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, ctime: actual_ctime)
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
          mock_file_lstat(path, ctime: actual_ctime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected ctime does not match the actual ctime' do
        let(:actual_ctime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, ctime: actual_ctime)
          expected_message = /expected ctime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the mtime: option' do
    subject { expect(path).to be_symlink(mtime: expected_mtime) }

    before { File.symlink(target_path, path) }

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
          mock_file_lstat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, mtime: actual_mtime)

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
          mock_file_lstat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now + 10 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, mtime: actual_mtime)
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
          mock_file_lstat(path, mtime: actual_mtime)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected mtime does not match the actual mtime' do
        let(:actual_mtime) { mocked_now - 20 }

        it 'should fail' do
          FileUtils.touch(path)
          mock_file_lstat(path, mtime: actual_mtime)
          expected_message = /expected mtime to be within 10 of 1967-03-15 00:16:00.000000000 -0700, but it was/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the target: option' do
    subject { expect(path).to be_symlink(target: expected_target) }

    before { File.symlink(target_path, path) }

    context 'when the expected target is not valid' do
      let(:expected_target) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `target:` to be a Matcher or String, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when given a String' do
      context 'when the expected target matches the actual target' do
        let(:expected_target) { target_path }

        it 'should not fail' do
          FileUtils.touch(path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected target does not match the actual target' do
        let(:expected_target) { 'not_target_path' }

        it 'should fail' do
          expected_message = /expected target to be "not_target_path", but it was "#{target_path}"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      context 'when the expected target matches the actual target' do
        let(:expected_target) { eq target_path }

        it 'should not fail' do
          FileUtils.touch(path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected target does not match the actual target' do
        let(:expected_target) { eq 'not_the_target' }

        it 'should fail' do
          FileUtils.touch(path)
          expected_message = /expected target to eq "not_the_target", but it was #{Regexp.escape(target_path.inspect)}/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the target_type: option' do
    subject { expect(path).to be_symlink(target_type: expected_target_type) }

    before { File.symlink(target_path, path) }

    context 'when the expected target type is not valid' do
      let(:expected_target_type) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `target_type:` to be a Matcher, String, or Symbol, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when the symlink target does not exist' do
      before do
        FileUtils.rm_rf(target_path)
      end

      let(:expected_target_type) { 'file' }

      it 'should fail' do
        expected_message = /expected the symlink target to exist/
        expect { subject }.to raise_error(expectation_not_met_error) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when given a Symbol' do
      let(:expected_target_type) { :file }

      context 'when the expected target type matches the actual target type' do
        it 'should not fail' do
          FileUtils.rm_rf(target_path)
          FileUtils.touch(target_path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected target type does not match the actual target type' do
        it 'should fail' do
          FileUtils.rm_rf(target_path)
          Dir.mkdir(target_path) # Create a directory instead of a file
          expected_message = /expected target_type to be "file", but it was "directory"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a String' do
      let(:expected_target_type) { 'directory' }

      context 'when the expected target type matches the actual target type' do
        it 'should not fail' do
          FileUtils.rm_rf(target_path)
          Dir.mkdir(target_path)
          expect { subject }.not_to raise_error
        end
      end
      context 'when the expected target type does not match the actual target type' do
        it 'should fail' do
          FileUtils.rm_rf(target_path)
          FileUtils.touch(target_path)
          expected_message = /expected target_type to be "directory", but it was "file"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_target_type) { match(/^(file|directory)$/) }

      context 'when the expected target type matches the actual target type' do
        it 'should not fail' do
          FileUtils.rm_rf(target_path)
          FileUtils.touch(target_path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected target type does not match the actual target type' do
        it 'should fail' do
          FileUtils.rm_rf(target_path)
          File.symlink('/tmp', target_path) # Create a symlink to a directory
          regexp_str = Regexp.escape('/^(file|directory)$/')
          expected_message = /expected target_type to match #{regexp_str}, but it was "link"/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end

  describe 'the target_exist: option' do
    subject { expect(path).to be_symlink(target_exist: expected_target_exist) }

    before { File.symlink(target_path, path) }

    context 'when the expected target exist is not valid' do
      let(:expected_target_exist) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `target_exist:` to be a Matcher, TrueClass, or FalseClass, but it was 123/
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to match(expected_message)
        end
      end
    end

    context 'when given a Boolean' do
      let(:expected_target_exist) { true }

      context 'when the expected target exist matches the actual target exist' do
        it 'should not fail' do
          FileUtils.rm_rf(target_path)
          FileUtils.touch(target_path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected target type does not match the actual target type' do
        it 'should fail' do
          FileUtils.rm_rf(target_path)
          expected_message = /expected target_exist to be true, but it was false/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end

    context 'when given a matcher' do
      let(:expected_target_exist) { be true }

      context 'when the expected target type matches the actual target type' do
        it 'should not fail' do
          FileUtils.rm_rf(target_path)
          FileUtils.touch(target_path)
          expect { subject }.not_to raise_error
        end
      end

      context 'when the expected target type does not match the actual target type' do
        it 'should fail' do
          FileUtils.rm_rf(target_path)
          expected_message = /expected target_exist to equal true, but it was false/
          expect { subject }.to raise_error(expectation_not_met_error) do |error|
            expect(error.message).to match(expected_message)
          end
        end
      end
    end
  end
end
