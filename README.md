# The rspec-path_matchers gem

[![Gem
Version](https://img.shields.io/gem/v/rspec-path_matchers.svg)](https://rubygems.org/gems/rspec-path_matchers)
[![Build
Status](https://img.shields.io/github/actions/workflow/status/main-branch/rspec-path_matchers/main.yml?branch=main)](https://github.com/main-branch/rspec-path_matchers/actions)
[![MIT
License](https://img.shields.io/badge/license-MIT-green)](https://opensource.org/licenses/MIT)

- [Summary](#summary)
- [Added Value](#added-value)
- [Installation](#installation)
- [Setup](#setup)
- [Usage \& Examples](#usage--examples)
  - [Basic Assertions](#basic-assertions)
  - [Negative Assertions (Checking for Absence)](#negative-assertions-checking-for-absence)
  - [File Content Assertions](#file-content-assertions)
  - [Attribute Assertions](#attribute-assertions)
  - [Directory Structure Assertions](#directory-structure-assertions)
  - [Exact Directory Contents](#exact-directory-contents)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Summary

**RSpec::PathMatchers** provides a comprehensive suite of RSpec matchers for
testing file system entries and structures.

Verifying that a generator, build script, or any file-manipulating process has
produced the correct output can be tedious and verbose. This gem makes those
assertions simple, declarative, and easier to read, allowing you to describe an entire
file tree and its properties within your specs. For example:

```ruby
require 'rspec/path_matchers'

RSpec.describe 'Generated Project' do
  it "should contain project files" do
    project_dir = Dir.pwd

    expect(project_dir).to(
      have_dir(".") do
        file("README.md", content: /MyProject/, birthtime: within(10_000).of(Time.now))
        dir("lib", exact: true) do
          file("my_project.rb")
          dir("my_project", exact: true) do
            file("version.rb", content: include('VERSION = "0.1.0"'), size: be < 1000)
          end
        end
      end
    )
  end
end
```

## Added Value

Here’s a breakdown of the value this API provides over what is available in standard
RSpec.

<h3>1. Abstraction and Readability: From Imperative to Declarative</h3>

Standard RSpec forces you to describe *how* to test something. This API allows you
to declaratively state *what* the directory structure should look like.

Without this API (Imperative Style):

```ruby
# This code describes the HOW: stat the file, get the mode, convert to octal...
# It's a script, not a specification.
path = '/var/www/html/index.html'
expect(File.exist?(path)).to be true
expect(File.stat(path).mode.to_s(8)[-4..]).to eq('0644')
expect(File.stat(path).owned?).to be true # This just checks if UID matches script runner
```

With this API (Declarative Style):

```ruby
# This code describes the WHAT. The implementation details are hidden.
# It reads like a specification document.
expect('/var/www/html').to have_file('index.html', mode: '0644', owner: 'httpd')
```

This hides the complex, imperative logic inside the matcher and exposes a clean,
readable, domain-specific language (DSL).

<h3>2. Conciseness and Cohesion: Grouping Related Assertions</h3>

Without this API, testing multiple attributes of a single file requires
fragmented, repetitive `expect` calls. Your API groups these assertions into one
cohesive, logical block.

Without this API:

```ruby
path = '/var/data/status.json'
expect(File.file?(path)).to be true
expect(File.size(path)).to be > 0
expect(File.read(path)).not_to include('error')
expect(JSON.parse(File.read(path))['status']).to eq('complete')
```

With this API:

```ruby
expect('/var/data').to have_file('status.json',
    size: be > 0,
    content: not(/error/),
    json_content: include('status' => 'complete')
)
```

This is far easier to read and maintain because all the assertions about
`status.json` are in one place.

<h3>3. The Nested Directory DSL Adds to the Expressive Power</h3>

This is where this API provides something that base RSpec simply cannot do
elegantly. Describing the state of a directory tree with standard RSpec is
incredibly verbose and difficult to read.

Without this API:

```ruby
# This is hard to read and mentally parse.
dir_path = '/etc/service/nginx'
expect(Dir.exist?(dir_path)).to be true
expect(File.exist?(File.join(dir_path, 'run'))).to be true
expect(Dir.exist?(File.join(dir_path, 'log'))).to be true
expect(File.exist?(File.join(dir_path, 'down'))).to be false
```

With this API:

```ruby
# This is a clear, hierarchical specification of the directory's contents.
expect('/etc/service').to(have_dir('nginx') do
    file('run')
    dir('log')
    no_file('down')
end)
```

The nested block is a leap in expressiveness and power, allowing you to write
complex integration and infrastructure tests with ease.

<h3>4. Descriptive and Intelligible Failure Messages</h3>

When a complex, nested expectation fails, this gem pinpoints the exact failure,
saving you valuable debugging time.

**Standard RSpec Failure:**

```text
expected: true
got: false
```

This kind of message forces you to manually inspect the directory structure to understand
what went wrong.

**With this API:**

You get a detailed, hierarchical report that shows the full expectation and
clearly marks what failed.

```text
the entry 'my-app' at '/tmp/d20250622-12345-abcdef' was expected to satisfy the following but did not:
- have directory "config" containing:
    - have file "database.yml" with owner "db_user" and mode "0600"
    - expected owner to be "db_user", but was "root"
    - expected mode to be "0600", but was "0644"
```

## Installation

Add this line to your application's `Gemfile` in the `:test` or `:development` group:

```ruby
group :test, :development do
  gem 'rspec-path_matchers'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install rspec-path_matchers
```

## Setup

Require the gem in your `spec/spec_helper.rb` file:

```ruby
# spec/spec_helper.rb
require 'rspec/path_matchers'
```

## Usage & Examples

All matchers operate on a base path, making your tests clean and portable.

### Basic Assertions

At its simplest, you can check for the existence of files and directories.

```ruby
it "creates the basic structure" do
  # Setup: Create some files and directories in our temp dir
  FileUtils.mkdir_p(File.join(@tmpdir, "app/models"))
  FileUtils.touch(File.join(@tmpdir, "config.yml"))

  # Assertions
  expect(@tmpdir).to have_file("config.yml")
  expect(@tmpdir).to have_dir("app")
end
```

### Negative Assertions (Checking for Absence)

You can use `not_to` to ensure that a file, directory, or symlink of a specific
type does not exist.

- `not_to have_file` passes if the entry is a directory, a symlink, or non-existent.
- `not_to have_dir` passes if the entry is a file, a symlink, or non-existent.
- `not_to have_symlink` passes if the entry is a file, a directory, or non-existent.

**Important:** Negative matchers cannot be given options (`:mode`, `:content`, etc.)
or blocks.

```ruby
it "can check for the absence of entries" do
  # Setup
  Dir.mkdir(File.join(@tmpdir, "existing_dir"))
  File.write(File.join(@tmpdir, "existing_file.txt"), "content")

  # Assert that a path that doesn't exist fails all checks
  expect(@tmpdir).not_to have_file("non_existent.txt")
  expect(@tmpdir).not_to have_dir("non_existent_dir")
  expect(@tmpdir).not_to have_symlink("non_existent_link")

  # Assert that an existing directory is NOT a file or symlink
  expect(@tmpdir).not_to have_file("existing_dir")
  expect(@tmpdir).not_to have_symlink("existing_dir")
  # expect(@tmpdir).not_to have_dir("existing_dir") # This would fail

  # Assert that an existing file is NOT a directory or symlink
  expect(@tmpdir).not_to have_dir("existing_file.txt")
  expect(@tmpdir).not_to have_symlink("existing_file.txt")
  # expect(@tmpdir).not_to have_file("existing_file.txt") # This would fail
end
```

### File Content Assertions

Go beyond existence and inspect what's inside a file.

```ruby
before do
  File.write(File.join(@tmpdir, "app.log"), "INFO: User logged in\nWARN: Low disk space")
  File.write(File.join(@tmpdir, "config.json"), '{"theme":"dark","version":2}')
  FileUtils.touch(File.join(@tmpdir, "empty.file"))
end

it "validates file content" do
  # Check for content with a string or regex
  expect(@tmpdir).to have_file("app.log", content: "INFO: User logged in")
  expect(@tmpdir).to have_file("app.log", content: /WARN:.*space/)

  # Check for the absence of content
  expect(@tmpdir).to have_file("app.log", content: not(/ERROR/))

  # Check if a file is empty
  expect(@tmpdir).to have_file("empty.file", size: 0)

  # Check for valid JSON and match its structure
  expect(@tmpdir).to have_file("config.json", json_content: {
    "theme" => "dark",
    "version" => an_instance_of(Integer)
  })
end
```

### Attribute Assertions

Matcher options allow detailed expectations on files, directories, and symlinks. Here
are the options available on the three top level matchers:

```ruby
expect(path).to have_file(
  name, mode:, owner:, group:, ctime:, mtime:, size:, content:, json_content:, yaml_content:,
)

expect(path).to have_dir(
  name, mode:, owner:, group:, ctime:, mtime:, exact:
)

expect(path).to have_symlink(
  name, mode:, owner:, group:, ctime:, mtime:, target:, target_type:, target_exist:
)
```

Here is a detailed example of using options:

```ruby
before do
  # Create a script, a secret key, and a symlink
  script_path = File.join(@tmpdir, "deploy.sh")
  File.write(script_path, "#!/bin/bash\n...")
  FileUtils.chmod(0755, script_path)

  key_path = File.join(@tmpdir, "secret.key")
  File.write(key_path, "KEY_DATA")
  FileUtils.chmod(0600, key_path)

  FileUtils.ln_s("deploy.sh", File.join(@tmpdir, "latest_script"))
end

it "validates file attributes" do
  # A single file can have many attributes checked at once
  expect(@tmpdir).to have_file("deploy.sh", mode: "0755", size: be > 10)

  # On Unix systems, you can check ownership
  current_user = Etc.getlogin
  expect(@tmpdir).to have_file("secret.key", owner: current_user, mode: "0600")

  # Check symlinks and their targets
  expect(@tmpdir).to have_symlink("latest_script", target: "deploy.sh")
end
```

### Directory Structure Assertions

The block syntax is the most powerful feature. It allows you to describe and verify
an entire file tree, including both the presence and *absence* of entries using
methods like `no_file`, `no_dir`, and `no_symlink`.

```ruby
before do
  # Generate a complex directory structure
  app_dir = File.join(@tmpdir, "my-app")
  FileUtils.mkdir_p(File.join(app_dir, "bin"))
  FileUtils.mkdir_p(File.join(app_dir, "config"))
  FileUtils.mkdir_p(File.join(app_dir, "log"))

  File.write(File.join(app_dir, "bin/run"), "#!/bin/bash")
  FileUtils.chmod(0755, File.join(app_dir, "bin/run"))

  File.write(File.join(app_dir, "config/database.yml"), "adapter: postgresql")
  FileUtils.ln_s("database.yml", File.join(app_dir, "config/db.yml"))
end

it "validates a nested directory structure" do
  # Note the parentheses around the matcher and its block
  expect(@tmpdir).to(have_dir("my-app") do
    # Assert on the 'bin' directory and its contents
    dir "bin" do
      file "run", mode: "0755", content: /bash/
    end

    # Assert on the 'config' directory and its contents
    dir "config" do
      file "database.yml"
      symlink "db.yml", target: "database.yml"
      no_file "secrets.yml" # Assert that a file is NOT present
    end

    # Assert that the 'log' directory is present and empty
    dir "log"

    # Assert the absence of other entries at the root of 'my-app'
    no_dir "tmp"
    no_file "README.md"
  end)
end
```

### Exact Directory Contents

You can enforce that a directory contains *only* the entries defined in your
specification block by using the `exact: true` option. This is perfect for testing
generators or build scripts that should produce a clean, specific output without any
extra files.

If any undeclared entries are found on the PathMatchers, the matcher will fail.

```ruby
it "creates a directory with only the expected files" do
  # Setup: Create a directory with an extra, unexpected file.
  FileUtils.mkdir(File.join(@tmpdir, 'dist'))
  File.write(File.join(@tmpdir, 'dist/app.js'), '// ...')
  File.write(File.join(@tmpdir, 'dist/unexpected.log'), 'debug info')

  # This test will fail because 'unexpected.log' was not declared.
  expect(@tmpdir).to(
    have_dir('dist', exact: true) do
      file 'app.js'
    end
  )
end

# Failure Message:
#
# the entry 'dist' at '...' was expected to satisfy the following but did not:
#   - did not expect entries ["unexpected.log"] to be present
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake
spec` to run the tests. You can also run `bin/console` for an interactive prompt that
will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/main-branch/rspec-path_matchers. This project is intended to be a
safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).