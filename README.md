# The rspec-path_matchers gem

[![Gem
Version](https://img.shields.io/gem/v/rspec-path_matchers.svg)](https://rubygems.org/gems/rspec-path_matchers)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/rspec-path_matchers/)
[![Change Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/ruby_git/file/CHANGELOG.md)
[![Continuous Integration](https://github.com/main-branch/rspec-path_matchers/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/main-branch/rspec-path_matchers/actions/workflows/continuous_integration.yml)
[![MIT
License](https://img.shields.io/badge/license-MIT-green)](https://opensource.org/licenses/MIT)

- [Summary](#summary)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
  - [Basic Assertions](#basic-assertions)
  - [Attribute Assertions](#attribute-assertions)
  - [Directory Content \& Nested Assertions](#directory-content--nested-assertions)
  - [Clear Failure Messages](#clear-failure-messages)
  - [Available Options](#available-options)
- [Added Value Over Standard RSpec Matchers](#added-value-over-standard-rspec-matchers)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Summary

**RSpec::PathMatchers** provides a comprehensive suite of RSpec matchers for
testing directory structures.

Verifying that a generator, build script, or any file-manipulating process has
produced the correct output can be tedious and verbose. This gem makes those
assertions simple, declarative, and easier to read, allowing you to describe an entire
file tree and its properties within your specs.

## Installation

Add this line to your application's `Gemfile` in the `:test` or `:development` group:

```ruby
group :test, :development do
  gem 'rspec-path_matchers'
end
```

OR add it to your project's `gemspec`:

```ruby
spec.add_development_dependency 'rspec-path_matchers'
```

And then execute:

```bash
bundle install
```

## Setup

Require the gem in your `spec/spec_helper.rb` file:

```ruby
# spec/spec_helper.rb
require 'rspec/path_matchers'

RSpec.configure do |config|
  config.include RSpec::PathMatchers
end
```

## Usage

### Basic Assertions

In their simplest forms, the `be_dir`, `be_file`, and `be_symlink` matchers **verify
the existence and type** of the given path. Each also supports negative expectations.

```ruby
# Check for existence and type
expect('/tmp/new_project').to be_dir

# Check for absence
expect('/tmp/new_project').not_to be_file
```

### Attribute Assertions

All top-level and nested matchers can take options as a hash to assert on specific
file attributes. The value of each option can be an RSpec matcher or a literal value.

```ruby
expect('config.yml').to be_file(content: include('production'), size: be < 1000)

expect('app.sock').to be_symlink(target: '/var/run/app.sock')
```

### Directory Content & Nested Assertions

The real power comes from describing the contents of a directory. The `#containing`
method asserts that a directory contains at least the specified entries, while
`#containing_exactly` asserts that it has exactly those entries and no others.

These expectations can be nested to any depth to describe a complete directory tree.

```ruby
expect('/var/www').to(
  be_dir.containing(
    file('index.html', mode: '0644'),
    dir('assets').containing_exactly(
      file('app.js'),
      file('style.css')
    ),
    no_file_named('config.php') # Assert that an entry does not exist
  )
)
```

Methods available as arguments to the containing methods include `dir`, `file`,
`symlink`, `no_file_named`, `no_dir_named`, and `no_symlink_named`.

### Clear Failure Messages

When an expectation is not met, this library gives well-formatted, easy-to-diagnose
error messages. If the index.html file from the previous example had the wrong
permissions AND style.css did not exist, the error would be:

```text
'/var/www' was not as expected:
  - index.html
      expected mode to be '0644', but it was '0600'
  - assets/style.css
      expected it to exist
```

### Available Options

Here is a list of all options that can be given to the matchers in this gem:

```ruby
mode:         <matcher|String>,
size:         <matcher|Integer>, # only for file matchers

# Owner and group require a Unix-like platform that supports the Etc module.
owner:        <matcher|String>,
group:        <matcher|String>,

# See `File.birthtime`, `File.atime`, etc. for platform support
birthtime:    <matcher|Time|DateTime>,
atime:        <matcher|Time|DateTime>,
ctime:        <matcher|Time|DateTime>,
mtime:        <matcher|Time|DateTime>,

# Content matchers are only for file matchers
content:      <matcher|String|Regexp>,
json_content: <matcher|true>,
yaml_content: <matcher|true>

# Target matchers are only for symlink matchers
target:       <matcher|String>
target_type:  <matcher|String|Symbol> # e.g., 'file', 'directory'
target_exist: <matcher|true|false>
```

## Added Value Over Standard RSpec Matchers

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
expect('/var/www/html/index.html').to be_file(mode: '0644', owner: 'httpd')
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
expect('/var/data/status.json').to be_file(
    size: be > 0,
    content: not_to(match(/error/)),
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
expect('/etc/service/nginx').to(
  be_dir.containing(
    file('run'),
    dir('log'),
    no_file_named('down')
  )
)
```

The nested `containing` matchers allows you to write tests that humans
can make sense of.

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

For this expectation:

```ruby
expect('config').to(
  be_dir.containing(
    file('database.xml', owner: 'db_user', mode: '0600')
  )
)
```

```text
'config' was not as expected:
  - database.xml
      expected owner to be "db_user", but was "root"
      expected mode to be "0600", but was "0644"
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