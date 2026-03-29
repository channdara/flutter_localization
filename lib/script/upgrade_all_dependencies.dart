import 'dart:io';

import 'package:yaml/yaml.dart';

/// Since {flutter pub upgrade} does not upgrade dependencies
/// inside project {pubspec.yaml} I create this script to do so.
/// This required to add {yaml} package to {pubspec.yaml} before run.
///
/// Run script command line:
///
/// dart run upgrade_all_dependencies.dart
///
/// Feel free to modify as you needed.
Future<void> main() async {
  try {
    final content = await File('pubspec.yaml').readAsString();
    final yaml = await loadYaml(content);
    final dependencies = yaml['dependencies'];
    final devDependencies = yaml['dev_dependencies'];
    final dependenciesToUpgrade = _getDependencies(dependencies);
    final devDependenciesToUpgrade = _getDependencies(devDependencies);
    await _runUpgrade(dependenciesToUpgrade);
    await _runUpgrade(devDependenciesToUpgrade, true);
  } catch (exception) {
    stderr.write(exception);
  }
}

List<String> _getDependencies(dynamic dependencies) {
  try {
    if (dependencies is Map<dynamic, dynamic>) {
      final List<String> dependenciesToUpgrade = [];
      dependencies.forEach((key, value) {
        if (value.toString().startsWith('^')) {
          dependenciesToUpgrade.add(key.toString());
        }
      });
      return dependenciesToUpgrade;
    }
    return [];
  } catch (exception) {
    stderr.write(exception);
    return [];
  }
}

Future<void> _runUpgrade(List<String> dependencies, [bool dev = false]) async {
  try {
    if (dependencies.isNotEmpty) {
      final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
      final result = await Process.run(executable, [
        'pub',
        'add',
        if (dev) '--dev',
        ...dependencies,
      ]);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
    }
  } catch (exception) {
    stderr.write(exception);
  }
}
