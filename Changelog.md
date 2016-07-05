Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.2.0 (2016-07-05)
-------------------------------------------------
Extended and easier configuration by autodetecting and multiple options.

- Add retry settings.
- Add autoloading of keys from users .ssh dir.
- Add test for multiple connections.
- Allow multiple server connections to try.
- Upgrade packages to alinex-exec@1.1.3, alinex-util@2.3.1, alinex-builder@2.1.13
- Autodetect current user as default value if no username is set.
- Add documentation of possible settings.
- Add more test and automatically deactivate if local key is missing.

Version 1.1.3 (2016-07-04)
-------------------------------------------------
- Disabled tests which run only locally.
- Allow all checks to run again.
- Remove endless connection tries and return error on problems.

Version 1.1.2 (2016-05-06)
-------------------------------------------------
- Update util and async calls.
- Upgraded async, util, chalk, portfinder, ssh2, exec and builder packages.
- Fixed general link in README.

Version 1.1.1 (2016-02-05)
-------------------------------------------------
- Updated packages for ssh, pathfinder and alinex classes.
- updated ignore files.
- Fixed style of test cases.
- Fixed lint warnings in code.
- Updated meta data of package and travis build versions.
- Added more tags tp package.json.

Version 1.1.0 (2015-11-09)
-------------------------------------------------
- Updated examples in documentation.
- Fixed both tunnels to work correctly also on multiple calls.
- Fixed bug in forwardOut and added socket test.
- Implement socksv5 proxy support.

Version 1.0.0 (2015-10-08)
-------------------------------------------------
- Document and add error handling and extended debugging.
- Made tunneling work with debugging.
- Framework for tunneling api.
- Initial commit

