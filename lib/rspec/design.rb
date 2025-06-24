# frozen_string_literal: true

########################################
# Matchers for file system objects
expect(path).to have_file(
  name, content:, json_content:, yaml_content:, size:, mode:, owner:, group:, ctime:, mtime:
)

expect(path).to have_dir(
  name, entry_count:, mode:, owner:, group:, ctime:, mtime:, exact:
)

expect(path).to have_symlink(
  name, mode:, owner:, group:, ctime:, mtime:, target:, target_type:, dangling:
)

########################################
# have_file matcher
expect(path).to have_file(name)

# Content checks
expect(path).to have_file(name, content: matcher | String | Regexp) # Matcher is compared to file content as a String
expect(path).to have_file(name, json_content: matcher | true) # ...the parsed file content as a Hash/Array/Object
expect(path).to have_file(name, yaml_content: matcher | true) # ...the parsed file content as a Hash/Array/Object
expect(path).to have_file(name, size: matcher) # ...the file size as an Integer

# Attribute checks
expect(path).to have_file(name, mode: matcher | String) # ...the file mode as a String (e.g. '0644')
expect(path).to have_file(name, owner: matcher | String) # ...the file owner as a String
expect(path).to have_file(name, group: matcher | String) # ...the file group as a String
expect(path).to have_file(name, ctime: matcher | Time) # ...the file creation time as a Time
expect(path).to have_file(name, mtime: matcher | Time) # ...the file modification time as a Time

########################################
# have_dir matcher
expect(path).to have_dir(name)

# Content checks
expect(path).to have_dir(name, entry_count: matcher) # Matcher is compared to the number of entries in the directory

# Attribute checks
expect(path).to have_dir(name, mode: matcher) # ...the directory mode as a String (e.g. '0755')
expect(path).to have_dir(name, owner: matcher) # ...the directory owner as a String
expect(path).to have_dir(name, group: matcher) # ...the directory group as a String
expect(path).to have_dir(name, ctime: matcher) # ...the directory creation time as a Time
expect(path).to have_dir(name, mtime: matcher) # ...the directory modification time as a Time

# Nested directory checks ()
expect(path).to(
  have_dir(name) do
    file('nested_file.txt', content: 'expected content')
    dir('nested_dir') do
      file('deeply_nested_file.txt', content: 'deeply expected content')
    end
    symlink('nested_symlink', target: 'expected_target')
    no_file('non_existent_file.txt')
    no_dir('non_existent_dir')
    no_symlink('non_existent_symlink')
    no_entry('non_existent_entry') # This checks for the absence of any type of entry with the given name
  end
)

########################################
# have_symlink matcher
expect(path).to have_symlink(name)

# Attribute checks
expect(path).to have_symlink(name, mode: mode_matcher) # Matcher is compared to symlink mode as a String (e.g. '0777')
expect(path).to have_symlink(name, owner: owner_matcher) # ...the symlink owner as a String
expect(path).to have_symlink(name, group: group_matcher) # ...the symlink group as a String
expect(path).to have_symlink(name, ctime: timestamp_matcher) # ...the symlink creation time as a Time
expect(path).to have_symlink(name, mtime: timestamp_matcher) # ...the symlink modification time as a Time

expect(path).to have_symlink(name, target: target_matcher) # ...the symlink target as a String
expect(path).to have_symlink(name, target_type: target_type)
expect(path).to have_symlink(name, target_exist?: boolean) # Assert whether the symlink is dangling or not
