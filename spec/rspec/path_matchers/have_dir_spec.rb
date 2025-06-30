# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'the have_dir matcher' do
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
    subject { expect(tmpdir).to have_dir(entry_name) }

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

  describe 'not_to have_dir' do
    subject { expect(tmpdir).not_to have_dir(entry_name) }

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
      subject { expect(tmpdir).not_to have_dir(entry_name, owner: 'user') }

      before { FileUtils.mkdir(path) }

      it 'should fail' do
        expected_message = 'The matcher `not_to have_dir(...)` cannot be given options'
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to include(expected_message)
        end
      end
    end

    context 'when given an expectation on its contents' do
      subject { expect(tmpdir).not_to have_dir(entry_name).containing(file('file1.txt')) }

      before { FileUtils.mkdir(path) }

      it 'should fail' do
        expected_message = 'The matcher `not_to have_dir(...)` cannot have expectations on its contents'
        expect { subject }.to raise_error(ArgumentError) do |error|
          expect(error.message).to include(expected_message)
        end
      end
    end
  end
end
