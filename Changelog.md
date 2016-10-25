Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.3.1 (2016-10-25)
-------------------------------------------------
- Fixed data referencing in schema.
- Fixed reference to ssh config.
- Better explain use of alternative ssh settings.
- Undo last changes.
- Change html comment style.
- Change github readme markdown.

Version 1.3.0 (2016-10-19)
-------------------------------------------------
- Remove alinex-exec as dev-dependency.
- Update portfinder@1.0.9, alinex-builder@2.3.9, alinex-validator@2.0.4
- Fix tests to skip on travis.
- Make npm test run verbose.
- Validate tunnel setup if debug enabled.
- Only call debug if it is enabled.
- Update internal documentation.
- Make schema more describable.
- Update documentation for configuration.
- Make debug config value optional.
- Update portfinder@1.0.7, alinex-config@1.4.0, alinex-util@2.4.2, async@2.1.2, alinex-builder@2.3.8, alinex-validator@2.0.1, ssh2@0.5.2
- Update travis checks.
- Merge pull request #2 from brumfb/bad_tunnel_spec
- Fix reference to connection setup data for tunnel spec
- Rename links to Alinex Namespace.
- Add copyright sign.
- Allow tunneling to work with new API.
- Start breaking change and allow external configuration.

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

