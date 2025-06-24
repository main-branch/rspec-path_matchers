# frozen_string_literal: true

require 'spec_helper'
require 'rspec/file_system'
require 'tmpdir'

RSpec.describe 'the have_dir matcher' do
  describe 'the exact: option' do
    around(:each) do |example|
      Dir.mktmpdir do |tmpdir|
        @tmpdir = tmpdir
        example.run
      end
    end

    let(:tmpdir) { @tmpdir }
    let(:expected_name) { 'my-app' }
    let(:path) { File.join(tmpdir, expected_name) }
    let(:expectation_not_met_error) { RSpec::Expectations::ExpectationNotMetError }

    before do
      Dir.mkdir(path)
    end

    context 'when exact: is not given' do
      subject { expect(tmpdir).to have_dir(expected_name) }

      it 'should default to non-exact behavior by ignoring unexpected files' do
        File.write(File.join(path, 'unexpected.txt'), 'content')
        expect { subject }.not_to raise_error
      end
    end

    context 'when the exact: value is not valid' do
      subject do
        expect(tmpdir).to(
          have_dir(expected_name, exact: 'invalid')
        )
      end

      it 'should raise an ArgumentError' do
        expected_message = '`exact:` must be true or false, but was "invalid"'
        expect { subject }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'when the exact: value is false' do
      context 'when the specification block expects some entries' do
        subject do
          expect(tmpdir).to(
            have_dir(expected_name, exact: false) do
              file('file1.txt')
              file('file2.txt')
            end
          )
        end

        context 'when the actual directory contains an unexpected entry' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
            File.write(File.join(path, 'file2.txt'), 'content')
            File.write(File.join(path, 'unexpected.txt'), 'content') # The extra file
          end

          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end

    context 'when the exact: value is true' do
      context 'when the specification block expects no entries' do
        subject do
          expect(tmpdir).to(
            have_dir(expected_name, exact: true) do
              # Intentionally empty -- no entries expected
            end
          )
        end

        context 'when the actual directory is empty' do
          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the actual directory is not empty' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
          end

          it 'should fail and list the unexpected entry' do
            expected_message = <<~MSG.chomp
              the entry 'my-app' at '#{tmpdir}' was expected to satisfy the following but did not:
                - did not expect entries ["file1.txt"] to be present
            MSG
            expect { subject }.to raise_error(expectation_not_met_error, expected_message)
          end
        end
      end

      context 'when the specification block expects multiple entries' do
        subject do
          expect(tmpdir).to(
            have_dir(expected_name, exact: true) do
              file 'file1.txt'
              dir 'subdir'
            end
          )
        end

        context 'when the actual directory contains only expected entries' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
            Dir.mkdir(File.join(path, 'subdir'))
          end
          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the actual directory contains multiple unexpected entries' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
            Dir.mkdir(File.join(path, 'subdir'))
            # Add unexpected entries
            File.write(File.join(path, 'unexpected_file.txt'), 'content')
            Dir.mkdir(File.join(path, 'unexpected_dir'))
            File.symlink('target', File.join(path, 'unexpected_link'))
          end

          it 'should fail and list all unexpected entries' do
            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to include(/"unexpected_file.txt"/)
              expect(error.message).to include(/"unexpected_dir"/)
              expect(error.message).to include(/"unexpected_link"/)
            end
          end
        end
      end

      context 'when the specification block includes no_* matchers' do
        subject do
          expect(tmpdir).to(
            have_dir(expected_name, exact: true) do
              file('file1.txt')
              no_file('file2.txt')
            end
          )
        end

        context 'when a negatively-asserted entry exists' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
            File.write(File.join(path, 'file2.txt'), 'content') # This file should not exist
          end
          it 'should fail with the `no_file` failure message' do
            # This ensures the `no_file` check runs and its failure message is prioritized.
            expected_message = /expected file 'file2.txt' not to be found at '.*', but it exists/
            expect { subject }.to raise_error(expectation_not_met_error, expected_message)
          end
        end

        context 'when no negatively-asserted entries exist' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
            # No file2.txt, so no failure expected
          end

          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end
  end
end
