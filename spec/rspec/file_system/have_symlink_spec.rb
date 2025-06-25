# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'the have_symlink matcher' do
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
  let(:target_path) { File.join(tmpdir, 'target') }

  let(:expectation_not_met_error) { RSpec::Expectations::ExpectationNotMetError }

  before do
    File.symlink(target_path, path)
  end

  describe 'checking existance' do
    subject { expect(tmpdir).to have_symlink(expected_name) }

    context 'when the entry at the given path is a symlink' do
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

    context 'when the entry at the given path is not a symlink' do
      before do
        FileUtils.rm(path)
        FileUtils.touch(path) # Create a regular file
      end

      it 'should fail' do
        expected_message = /expected it to be a symlink/
        expect { subject }.to raise_error(expectation_not_met_error, expected_message)
      end
    end
  end

  describe 'not_to have_symlink' do
    context 'with no options and no block' do
      subject { expect(tmpdir).not_to have_symlink(expected_name) }

      context 'when the entry at the given path does not exist' do
        before { FileUtils.rm_rf(path) }
        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the entry at the given path is a directory' do
        before do
          FileUtils.rm_rf(path)
          Dir.mkdir(path)
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the entry at the given path is a file' do
        before do
          FileUtils.rm_rf(path)
          File.write(path, 'I am a file')
        end

        it 'should not fail' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the entry at the given path is a symlink to a directory' do
        before do
          Dir.mkdir(target_path)
        end

        it 'should fail' do
          expected_message = /expected it not to be a symlink/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end

      context 'when the entry at the given path is a symlink to a file' do
        let(:target_file) { File.join(tmpdir, 'target_file.txt') }

        before do
          File.write(target_path, 'I am a file')
        end

        it 'should fail' do
          expected_message = /expected it not to be a symlink/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end

      context 'when the entry at the given path is a dangling symlink' do
        let(:dangling_target) { File.join(tmpdir, 'non_existent_target') }

        # The top level `before` block creates a dangling symlink

        it 'should fail' do
          expected_message = /expected it not to be a symlink/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end

    context 'with any options' do
      subject { expect(tmpdir).not_to have_symlink(expected_name, owner: 'root') }

      it 'should raise an ArgumentError' do
        expected_message = 'The matcher `not_to have_symlink(...)` cannot be given options'
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end
  end

  context 'when given invalid options' do
    before do
      FileUtils.touch(File.join(tmpdir, expected_name))
    end

    subject { expect(tmpdir).to have_symlink(expected_name, **options) }

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

  describe 'the owner: option' do
    subject { expect(tmpdir).to have_symlink(expected_name, owner: expected_owner) }

    def mock_owner(path, actual_owner)
      uid = 9999
      allow(File).to receive(:lstat).with(path).and_return(double(uid: uid))
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
    subject { expect(tmpdir).to have_symlink(expected_name, group: expected_group) }

    # Etc.getgrgid(File.stat(path).gid).name
    def mock_group(path, name)
      gid = 9999
      allow(File).to receive(:lstat).with(path).and_return(double(gid:))
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
    subject { expect(tmpdir).to have_symlink(expected_name, atime: expected_atime) }

    def mock_atime(path, actual_atime)
      allow(File).to receive(:lstat).with(path).and_return(double(atime: actual_atime))
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
    subject { expect(tmpdir).to have_symlink(expected_name, birthtime: expected_birthtime) }

    def mock_birthtime(path, actual_birthtime)
      allow(File).to receive(:lstat).with(path).and_return(double(birthtime: actual_birthtime))
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
    subject { expect(tmpdir).to have_symlink(expected_name, ctime: expected_ctime) }

    def mock_ctime(path, actual_ctime)
      allow(File).to receive(:lstat).with(path).and_return(double(ctime: actual_ctime))
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
    subject { expect(tmpdir).to have_symlink(expected_name, mtime: expected_mtime) }

    def mock_mtime(path, actual_mtime)
      allow(File).to receive(:lstat).with(path).and_return(double(mtime: actual_mtime))
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

  describe 'the target: option' do
    subject { expect(tmpdir).to have_symlink(expected_name, target: expected_target) }

    context 'when the expected target is not valid' do
      let(:expected_target) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `target:` to be a Matcher or a String, but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
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
          expected_message = /expected target to be "not_target_path", but was "#{target_path}"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expected_message = /expected target to eq "not_the_target", but was #{Regexp.escape(target_path.inspect)}/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the target_type: option' do
    subject { expect(tmpdir).to have_symlink(expected_name, target_type: expected_target_type) }

    context 'when the expected target type is not valid' do
      let(:expected_target_type) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `target_type:` to be a Matcher, a String, or a Symbol but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when the symlink target does not exist' do
      before do
        FileUtils.rm_rf(target_path)
      end

      let(:expected_target_type) { 'file' }

      it 'should fail' do
        expected_message = /expected the symlink target to exist/
        expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expected_message = /expected target_type to be "file", but was "directory"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expected_message = /expected target_type to be "directory", but was "file"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expected_message = /expected target_type to match #{regexp_str}, but was "link"/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end

  describe 'the target_exist: option' do
    subject { expect(tmpdir).to have_symlink(expected_name, target_exist: expected_target_exist) }

    context 'when the expected target exist is not valid' do
      let(:expected_target_exist) { 123 }

      it 'should raise an ArgumentError' do
        expected_message = /expected `target_exist:` to be a Matcher, true, or false but was 123/
        expect { subject }.to raise_error(ArgumentError, expected_message)
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
          expected_message = /expected target_exist to be true, but was false/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
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
          expected_message = /expected target_exist to equal true, but was false/
          expect { subject }.to raise_error(expectation_not_met_error, expected_message)
        end
      end
    end
  end
end
