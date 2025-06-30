# frozen_string_literal: true

require 'rspec/mocks'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # This line includes the module containing `any`, `an_instance_of`, etc.,
  # making them available within all RSpec examples (it blocks).
  config.include RSpec::Mocks::ArgumentMatchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Guard for Unix-specific tests, as Windows does not have the same ownership concepts
UNIX_PLATFORM = RUBY_PLATFORM !~ /cygwin|mswin|mingw|bccwin|wince|emx/

# Helper method to get the current user for ownership tests
def current_user
  Etc.getpwuid(Process.uid).name
end

# Helper method to get the current group for ownership tests
def current_group
  Etc.getgrgid(Process.gid).name
end

RSpec.shared_examples 'an abstract class method' do
  it 'raises NotImplementedError' do
    expect { subject }.to raise_error(NotImplementedError) do |e|
      class_name = described_class.to_s.split('::').last
      method_name = e.backtrace_locations.first.label.split('::').last.split('.').last
      expect(e.message).to eq("Subclasses must implement #{class_name}.#{method_name}")
    end
  end
end

RSpec.shared_examples 'an abstract method' do
  it 'raises NotImplementedError' do
    expect { subject }.to raise_error(NotImplementedError) do |e|
      class_name = described_class.to_s.split('::').last
      method_name = e.backtrace_locations.first.label.split('::').last.split('#').last
      expect(e.message).to eq("Subclasses must implement #{class_name}##{method_name}")
    end
  end
end

def mocked_now
  @mocked_now ||= Time.new(1967, 3, 15, 0, 16, 0, '-0700').freeze
end

def mock_user_name(uid, name)
  allow(Etc).to receive(:getpwuid).with(uid).and_return(double(name:))
end

def mock_group_name(gid, name)
  allow(Etc).to receive(:getgrgid).with(gid).and_return(double(name:))
end

def mock_file_stat(
  path,
  atime: mocked_now, birthtime: mocked_now, ctime: mocked_now, mtime: mocked_now,
  uid: 9999, gid: 9999, mode: 0o644
)
  allow(File).to(
    receive(:stat).with(path).and_return(
      double(
        atime:, birthtime:, ctime:, mtime:,
        uid:, gid:, mode:
      )
    )
  )
end

def mock_file_lstat(
  path,
  atime: mocked_now, birthtime: mocked_now, ctime: mocked_now, mtime: mocked_now,
  uid: 9999, gid: 9999, mode: 0o644
)
  allow(File).to(
    receive(:lstat).with(path).and_return(
      double(
        atime:, birthtime:, ctime:, mtime:,
        uid:, gid:, mode:
      )
    )
  )
end

def expectation_not_met_error = RSpec::Expectations::ExpectationNotMetError

require 'simplecov-rspec'

SimpleCov.enable_coverage :branch

def ci_build? = ENV.fetch('GITHUB_ACTIONS', 'false') == 'true'

SimpleCov::RSpec.start(list_uncovered_lines: ci_build?) do
  minimum_coverage line: 100, branch: 100
end

require 'rspec/path_matchers'

RSpec.configure do |config|
  config.include RSpec::PathMatchers
end
