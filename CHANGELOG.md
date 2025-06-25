## [Unreleased]

## [0.1.1](https://github.com/main-branch/rspec-path_matchers/compare/v0.1.0...v0.1.1) (2025-06-25)


### Bug Fixes

* Rename the `target_exist?` option to `target_exist` ([8c77c08](https://github.com/main-branch/rspec-path_matchers/commit/8c77c08736d90cacfb4c8248d15f57eee8774a43))


### Other Changes

* Rename the project gemspec to match the gem name ([ece0738](https://github.com/main-branch/rspec-path_matchers/commit/ece07380fa1ae085a5a4a8c24a50c05978a16f76))

## 0.1.0 (2025-06-25)


### ⚠ BREAKING CHANGES

* update lowest version of Ruby supported from 3.1.x to 3.2.x
* rename the gem from rspec-file_systems to rspec-path_matchers

### Features

* Add custom description for each matcher ([a305d05](https://github.com/main-branch/rspec-path_matchers/commit/a305d05a4008b3ec0e2f5e052ecb4960d99b0bdf))
* Add nested matchers for the have_directory matcher ([d0fc5bf](https://github.com/main-branch/rspec-path_matchers/commit/d0fc5bff30bac4c5ce22bfa65c0348918c8f7a74))
* Add options to the have_symlink matcher to test the symlink target and target type ([6228db4](https://github.com/main-branch/rspec-path_matchers/commit/6228db4b768a9792fc93f2fc0e8263d7261c8f12))
* Add support for negative (aka not_to) matches in have_file, have_dir, and have_symlink ([69bdc59](https://github.com/main-branch/rspec-path_matchers/commit/69bdc595f764778d4bca33ff4d6d2b20fbeb7e7b))
* Add the 'target_exist?' option to the have_symlink matcher ([a47c900](https://github.com/main-branch/rspec-path_matchers/commit/a47c90049d39e87c5a4f9bdf8652c83ed7ad8a19))
* Allow no_file, no_dir, and no_symlink matchers in the have_dir block ([43b0c67](https://github.com/main-branch/rspec-path_matchers/commit/43b0c67e3f56b73a708e59f16a667c5e37adecd5))
* Implement the have_dir exact option ([9a405ce](https://github.com/main-branch/rspec-path_matchers/commit/9a405ce92561c276679f8408184d0c256a066bf4))
* Initial versions of the have_file, have_dir and have_symlink matchers ([51a9e2e](https://github.com/main-branch/rspec-path_matchers/commit/51a9e2e836a5238f2bf311116970dd49400a89a1))
* Initial versions of the have_file, have_dir and have_symlink matchers ([31e6228](https://github.com/main-branch/rspec-path_matchers/commit/31e62285d536aa5b5cba26708eeaf93cf4b7e4c1))
* Rename the gem from rspec-file_systems to rspec-path_matchers ([6c36917](https://github.com/main-branch/rspec-path_matchers/commit/6c36917fa1d07176960fce5aec1cac98d8e0b584))
* Update lowest version of Ruby supported from 3.1.x to 3.2.x ([7206fa8](https://github.com/main-branch/rspec-path_matchers/commit/7206fa8418a6e1beb7171ecce31b539384ff90d0))


### Bug Fixes

* Correct rubocop offenses in the design doc ([9906b5d](https://github.com/main-branch/rspec-path_matchers/commit/9906b5d980eb8c23591db5a1a0bb8c06bdbfa43f))
* Fix the description of the json and yaml matchers when given 'true' ([fd84705](https://github.com/main-branch/rspec-path_matchers/commit/fd84705962ec8b52ae0405140ae0cb96c03d589c))


### Other Changes

* Add tests for the have_dir exact: option ([01e8708](https://github.com/main-branch/rspec-path_matchers/commit/01e8708a6c4104cb1a337b948a0d89a51fbffebf))
* Call the block passed to the HaveDirectory matcher `specification_block` ([2cd2587](https://github.com/main-branch/rspec-path_matchers/commit/2cd2587088d6ad28296454c884d8b3a6a5c84724))
* Do not run yard:audit or yard:coverage as part of the CI build ([c8f3471](https://github.com/main-branch/rspec-path_matchers/commit/c8f3471f0a342c74a019ffe3892c1d48fcdca0d0))
* Implement continuous delivery ([818567d](https://github.com/main-branch/rspec-path_matchers/commit/818567df9f53515607d105430557468d775d815c))
* Reset gem version for CD pipeline ([640bf30](https://github.com/main-branch/rspec-path_matchers/commit/640bf30926766a7299282fdfe3a2cde0738cfe9c))
* Reset gem version for CD pipeline ([ade971a](https://github.com/main-branch/rspec-path_matchers/commit/ade971a35cd365e18ffbced2a4b28e4c36a0c2f2))

## [0.1.0] - 2025-06-07

- Initial release
