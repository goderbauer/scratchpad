import 'dart:convert';
import 'dart:io';

import 'package:dart2bytecode/dart2bytecode.dart' as dart2bytecode;
import 'package:path/path.dart' as p;

void main() async {
  print(await compile());
}

Future<String?> compile() async {
  final libraryName = 'package:compass_app/main.dart';
  final assetsDbcPath = '/Users/goderbauer/dev/flutterpad-mobile/assets/dbc';

  final outputDir = await Directory.systemTemp.createTemp();

  final packageConfigPath = await _createPackageConfig(
    p.join(assetsDbcPath, 'package_config.json'),
    Directory.current,
    outputDir,
  );

  final output = await File(p.join(outputDir.path, 'out.bytecode')).create();

  final compilerMessages = <String>[];

  final exitCode = await dart2bytecode.runCompilerWithOptions(
    input: libraryName,
    platformKernel: p.join(assetsDbcPath, 'platform_strong.dill'),
    outputFileName: output.path,
    targetName: 'flutter',
    environmentDefines: {'dart.vm.profile': 'false', 'dart.vm.product': 'true'},
    packages: packageConfigPath.path,
    importDill: p.join(assetsDbcPath, 'host_app_not_aot.dill'),
    // validateDynamicInterface: p.join(assetsDbcPath, 'dynamic_interface.yaml'),
    printMessage: (message) {
      print(message);
      compilerMessages.add(message);
    },
  );

  return (exitCode != 0) ? compilerMessages.join('\n') : null;
}

Future<File> _createPackageConfig(
  String packageConfig,
  Directory root,
  Directory out,
) async {
  final packageConfigJson = jsonDecode(
    await File(packageConfig).readAsString(),
  );
  for (final package in packageConfigJson['packages']) {
    if (package['name'] == 'flutterpad') {
      package['name'] = 'compass_app';
      package['rootUri'] = Uri.file(root.path).toString();
      break;
    }
  }
  var file = File(p.join(out.path, 'package_config.json'));
  await file.writeAsString(jsonEncode(packageConfigJson));
  return file;
}
