# frozen_string_literal: true

require 'spec_helper'
require 'rspec/path_matchers'
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

  before { Dir.mkdir(path) }

  context 'with an expectation on the contents' do
    context 'when #containing is called more than once on the same matcher' do
      subject do
        expect(path).to(be_dir.containing(file('file1.txt')).containing(file('file2.txt')))
      end

      it 'should raise an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError) do |error|
          expected_message = <<~MESSAGE.chomp
            Collectively, `#containing` and `#containing_exactly` may be called only once
          MESSAGE
          expect(error.message).to include(expected_message)
        end
      end
    end

    context 'when #containing_exactly is called more than once on the same matcher' do
      subject do
        expect(path).to(
          be_dir.containing_exactly(file('file1.txt')).containing_exactly(file('file2.txt'))
        )
      end

      it 'should raise an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError) do |error|
          expected_message = <<~MESSAGE.chomp
            Collectively, `#containing` and `#containing_exactly` may be called only once
          MESSAGE
          expect(error.message).to include(expected_message)
        end
      end
    end

    context 'when both #containing and #containing_exactly are used together on the same matcher' do
      subject do
        expect(path).to(
          be_dir.containing(file('file1.txt')).containing_exactly(file('file2.txt'))
        )
      end

      it 'should raise an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError) do |error|
          expected_message = <<~MESSAGE.chomp
            Collectively, `#containing` and `#containing_exactly` may be called only once
          MESSAGE
          expect(error.message).to include(expected_message)
        end
      end
    end

    context 'when setting expectations with #containing' do
      subject do
        expect(tmpdir).to(
          be_dir.containing(
            dir(entry_name).containing(
              file('file1.txt'),
              file('file2.txt')
            )
          )
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

    context 'when setting expectations with #containing_exactly' do
      context 'when the specification block expects no entries' do
        subject do
          # TODO: maybe add an option for `empty`, or `entry_count`, or `containing_nothing`
          expect(tmpdir).to(
            be_dir.containing(
              dir(entry_name).containing_exactly
            )
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
            expected_message = <<~MESSAGE.chomp
              #{tmpdir} was not as expected:
                - #{entry_name}
                    expected no other entries, but found ["file1.txt"]
            MESSAGE

            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to eq(expected_message)
            end
          end
        end
      end

      context 'when the specification block expects multiple entries' do
        subject do
          expect(tmpdir).to(
            be_dir.containing(
              dir(entry_name).containing_exactly(
                file('file1.txt'),
                dir('subdir'),
                symlink('link_to_target')
              )
            )
          )
        end

        context 'when the actual directory contains only expected entries' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
            Dir.mkdir(File.join(path, 'subdir'))
            File.symlink('target', File.join(path, 'link_to_target'))
          end

          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the actual directory contains multiple unexpected entries' do
          before do
            File.write(File.join(path, 'file1.txt'), 'content')
            Dir.mkdir(File.join(path, 'subdir'))
            File.symlink('target', File.join(path, 'link_to_target'))
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
            be_dir.containing(
              dir(entry_name).containing_exactly(
                file('file1.txt'),
                no_file_named('file2.txt')
              )
            )
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
            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to match(expected_message)
            end
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

      context 'when setting expectations with #containing_exactly on a nested directory' do
        subject do
          expect(tmpdir).to(
            be_dir.containing(
              dir(entry_name).containing_exactly(
                dir('nested_dir').containing_exactly(file('file.txt'))
              )
            )
          )
        end

        context 'when the nested directory contains the expected file' do
          before do
            nested_dir = File.join(path, 'nested_dir')
            Dir.mkdir(nested_dir)
            File.write(File.join(nested_dir, 'file.txt'), 'content')
          end

          it 'should not fail' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the nested directory does not contain the expected file' do
          before do
            nested_path = File.join(path, 'nested_dir')
            Dir.mkdir(nested_path)
          end

          it 'should fail with a message about the missing file' do
            expected_message = <<~MESSAGE.chomp
              #{tmpdir} was not as expected:
                - #{entry_name}/nested_dir/file.txt
                    expected it to exist
            MESSAGE

            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to eq(expected_message)
            end
          end
        end

        context 'when the nested directory contains unexpected entries' do
          before do
            nested_path = File.join(path, 'nested_dir')
            Dir.mkdir(nested_path)
            File.write(File.join(nested_path, 'file.txt'), 'content')
            File.write(File.join(nested_path, 'unexpected_file1.txt'), 'content')
            File.write(File.join(nested_path, 'unexpected_file2.txt'), 'content')
          end

          it 'should fail and list the unexpected entries' do
            expected_message = <<~MESSAGE.chomp
              #{tmpdir} was not as expected:
                - dir/nested_dir
                    expected no other entries, but found ["unexpected_file1.txt", "unexpected_file2.txt"]
            MESSAGE
            expect { subject }.to raise_error(expectation_not_met_error) do |error|
              expect(error.message).to eq(expected_message)
            end
          end
        end
      end
    end
  end
end
