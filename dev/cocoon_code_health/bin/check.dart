// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:cocoon_code_health/src/checks.dart';
import 'package:cocoon_code_health/src/checks/do_not_submit_fixme.dart';
import 'package:cocoon_code_health/src/checks/use_test_logging.dart';
import 'package:cocoon_common/cocoon_common.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;

final _parser =
    ArgParser(allowTrailingOptions: false)
      ..addOption(
        'repository-root',
        help: 'The root of the flutter/cocoon repository.',
        defaultsTo: _findRepositoryRoot(),
      )
      ..addFlag('verbose', abbr: 'v', help: 'Show additional output');

void main(List<String> args) async {
  final parsed = _parser.parse(args);
  final cocoon = parsed.option('repository-root');
  if (cocoon == null) {
    io.stderr.writeln('Could not find the repository root');
    io.exitCode = 1;
    return;
  }

  final verbose = parsed.flag('verbose');
  const fs = LocalFileSystem();

  for (final server in const ['app_dart', 'auto_submit']) {
    final package = p.join(cocoon, server);
    for (final check in const [UseTestLogging(), DoNotSubmitFixme()]) {
      io.stderr.writeln('Running ${check.runtimeType} on $package...');

      // Look at tracked files using git ls-files.
      final gitLsFiles = io.Process.runSync('git', ['-C', package, 'ls-files']);
      if (gitLsFiles.exitCode != 0) {
        io.stderr.writeln(gitLsFiles.stderr);
        io.exitCode = 1;
        return;
      }
      final trackedFiles = (gitLsFiles.stdout as String)
          .split('\n')
          .map((p) => fs.file(fs.path.join(package, p)));
      for (final file in trackedFiles) {
        if (!check.include.any((g) => g.matches(file.path))) {
          continue;
        }
        final relative = p.relative(file.path, from: cocoon);
        if (check.exclude.any((g) => g.matches(relative))) {
          if (verbose) {
            io.stderr.writeln('${check.runtimeType} $relative: Skip');
          }
          continue;
        }
        final logger = BufferedLogger();
        final result = await check.check(logger, file);
        if (result == CheckResult.failed) {
          io.exitCode = 1;
          for (final message in logger.messages) {
            io.stderr.writeln(
              '${message.severity.name}: ${check.runtimeType}\n'
              '$relative\n'
              '${message.message}\n',
            );
          }
        } else if (verbose) {
          io.stderr.writeln('${check.runtimeType} $relative: Pass');
        }
      }
    }
  }

  io.stderr.writeln('Done!');
}

String? _findRepositoryRoot() {
  var current = io.Directory.current;
  while (true) {
    final pubspec = io.File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final contents = pubspec.readAsStringSync();
      if (contents.contains('name: _cocoon_workspace')) {
        return current.path;
      }
    }
    if (p.equals(current.path, current.parent.path)) {
      return null;
    }
    current = current.parent;
  }
}
