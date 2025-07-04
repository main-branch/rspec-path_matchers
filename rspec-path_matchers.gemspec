# frozen_string_literal: true

require_relative 'lib/rspec/path_matchers/version'

Gem::Specification.new do |spec|
  spec.name = 'rspec-path_matchers'
  spec.version = RSpec::PathMatchers::VERSION
  spec.authors = ['James Couball']
  spec.email = ['jcouball@yahoo.com']

  spec.summary = 'A comprehensive RSpec matcher suite for testing file system entries and structures'
  spec.description = <<~DESCRIPTION
    Provides a rich DSL for RSpec to assert on files, directories, and
    symlinks, including permissions, content (including JSON), and more. Ideal for
    testing generators and build scripts.
  DESCRIPTION

  spec.homepage = 'https://github.com/main-branch/rspec-path_matchers'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"

  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'irb', '~> 1.15'
  spec.add_development_dependency 'main_branch_shared_rubocop_config', '~> 0.1'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'redcarpet', '~> 3.6'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.74'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov-rspec', '~> 0.4'
  spec.add_development_dependency 'yard', '~> 0.9', '>= 0.9.28'
  spec.add_development_dependency 'yardstick', '~> 0.9'

  spec.add_dependency 'rspec-core', '~> 3.13'
  spec.add_dependency 'rspec-expectations', '~> 3.13'
end
