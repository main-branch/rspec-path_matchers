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

require 'simplecov-rspec'

SimpleCov.enable_coverage :branch

def ci_build? = ENV.fetch('GITHUB_ACTIONS', 'false') == 'true'

SimpleCov::RSpec.start(list_uncovered_lines: ci_build?) do
  minimum_coverage line: 100, branch: 100
end

require 'rspec/path_matchers'
