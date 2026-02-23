import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('runs on current project and finds RootClass', () {
    final result = Process.runSync(
      'dart',
      ['bin/api_surface_area.dart', '.', 'RootClass'],
    );

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Found class "RootClass"'));
    expect(result.stdout, contains('package:api_surface_area/api_surface_area.dart'));
    expect(result.stdout, contains('RootClass'));
  });

  test('runs on current project in full package mode', () {
    final result = Process.runSync(
      'dart',
      ['bin/api_surface_area.dart', '.'],
    );

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Collecting all public types in the package...'));
    expect(result.stdout, contains('api_surface_area: 5 types'));
  });

  test('errors on non-existent class', () {
    final result = Process.runSync(
      'dart',
      ['bin/api_surface_area.dart', '.', 'NonExistentClass'],
    );

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Error: Class "NonExistentClass" not found'));
  });
}
