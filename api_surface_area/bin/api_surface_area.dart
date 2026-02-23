import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('dot-file', abbr: 'd', help: 'Path to output a DOT file.')
    ..addFlag('hide-dart', help: 'Hide types from the dart: SDK in the graph.', negatable: false);

  ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print('Error: $e');
    _printUsage(parser);
    exit(1);
  }

  if (results.rest.length != 2) {
    _printUsage(parser);
    exit(1);
  }

  final rootPath = p.canonicalize(results.rest[0]);
  final className = results.rest[1];
  final dotFile = results['dot-file'] as String?;
  final hideDart = results['hide-dart'] as bool;

  if (!Directory(rootPath).existsSync()) {
    print('Error: Directory does not exist: $rootPath');
    exit(1);
  }

  print('Analyzing codebase at $rootPath...');
  final collection = AnalysisContextCollection(includedPaths: [rootPath]);
  final context = collection.contextFor(rootPath);
  final session = context.currentSession;

  final classElement = await _findClassElement(context, session, className);
  if (classElement == null) {
    print('Error: Class "$className" not found in the codebase.');
    exit(1);
  }

  print('Found class "${classElement.displayName}" in ${classElement.library.uri}');
  print('Collecting exposed types transitively...');

  final collector = _TypeCollector(hideDart: hideDart);
  collector.collect(classElement.thisType, null);

  print('\nExposed type graph:');
  _printGraph(classElement, collector.graph);

  if (dotFile != null) {
    _writeDotFile(dotFile, classElement, collector.graph);
  }

  final exposedElements = collector.visitedElements
      .where((e) =>
          e is InterfaceElement || e is TypeAliasElement || e is EnumElement)
      .toList();

  final grouped = <String, List<Element>>{};
  final packageCounts = <String, int>{};

  for (final element in exposedElements) {
    final libraryUri = element.library?.uri.toString() ?? 'unknown';
    grouped.putIfAbsent(libraryUri, () => []).add(element);

    final packageName = _getPackageName(libraryUri);
    packageCounts[packageName] = (packageCounts[packageName] ?? 0) + 1;
  }

  print('\nSummary by package:');
  final sortedPackages = packageCounts.keys.toList()..sort();
  for (final pkg in sortedPackages) {
    print('- $pkg: ${packageCounts[pkg]} types');
  }

  final sortedLibraries = grouped.keys.toList()..sort();

  print('\nExposed types by library:');
  for (final libraryUri in sortedLibraries) {
    print('\n$libraryUri:');
    final elements = grouped[libraryUri]!
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    for (final element in elements) {
      print('- ${element.displayName}');
    }
  }
}

void _printUsage(ArgParser parser) {
  print('Usage: api_surface_area <path_to_codebase> <class_name> [options]');
  print(parser.usage);
}

void _printGraph(Element root, Map<Element, Set<Element>> graph) {
  final visited = <Element>{};
  void printNode(Element node, int indent) {
    final prefix = '  ' * indent;
    final libraryUri = node.library?.uri.toString() ?? 'unknown';
    if (visited.contains(node)) {
      print('$prefix- ${node.displayName} ($libraryUri) [already listed]');
      return;
    }
    visited.add(node);
    print('$prefix- ${node.displayName} ($libraryUri)');

    final children = graph[node]?.toList() ?? [];
    children.sort((a, b) => a.displayName.compareTo(b.displayName));
    for (final child in children) {
      printNode(child, indent + 1);
    }
  }

  printNode(root, 0);
}

void _writeDotFile(String filePath, Element root, Map<Element, Set<Element>> graph) {
  final sb = StringBuffer();
  sb.writeln('digraph G {');
  sb.writeln('  rankdir=LR;');
  sb.writeln('  node [shape=box, fontname="Arial"];');

  final visited = <Element>{};
  void traverse(Element node) {
    if (visited.contains(node)) return;
    visited.add(node);

    final nodeName = node.displayName;
    final libraryUri = node.library?.uri.toString() ?? 'unknown';
    // Escape quotes for DOT
    final label = '$nodeName\\n($libraryUri)'.replaceAll('"', '\\"');
    sb.writeln('  n${node.id} [label="$label"];');

    final children = graph[node] ?? {};
    for (final child in children) {
      sb.writeln('  n${node.id} -> n${child.id};');
      traverse(child);
    }
  }

  traverse(root);
  sb.writeln('}');
  File(filePath).writeAsStringSync(sb.toString());
  print('\nDOT file written to $filePath');
}

String _getPackageName(String uri) {
  if (uri.startsWith('package:')) {
    final parts = uri.split('/');
    if (parts.isNotEmpty) {
      return parts[0].replaceFirst('package:', '');
    }
  } else if (uri.startsWith('dart:')) {
    return 'dart';
  }
  return 'unknown';
}

Future<InterfaceElement?> _findClassElement(
    AnalysisContext context, AnalysisSession session, String className) async {
  for (final filePath in context.contextRoot.analyzedFiles()) {
    if (!filePath.endsWith('.dart')) continue;

    final unitResult = await session.getUnitElement(filePath);
    if (unitResult is! UnitElementResult) continue;

    final library = unitResult.fragment.element;
    for (final clazz in library.classes) {
      if (clazz.name == className) return clazz;
    }
    for (final mixin in library.mixins) {
      if (mixin.name == className) return mixin;
    }
    for (final enum_ in library.enums) {
       if (enum_.name == className) return enum_;
    }
  }
  return null;
}

class _TypeCollector {
  final bool hideDart;
  final Map<Element, Set<Element>> graph = {};
  final Set<Element> visitedElements = {};

  _TypeCollector({required this.hideDart});

  void collect(DartType? type, Element? parent) {
    if (type == null) return;

    final element = type.element;
    if (element != null && !element.isPrivate) {
      final libraryUri = element.library?.uri.toString() ?? 'unknown';
      final isDart = libraryUri.startsWith('dart:');

      if (element is InterfaceElement ||
          element is TypeAliasElement ||
          element is EnumElement) {
        if (parent != null && parent != element) {
          if (!hideDart || !isDart) {
            graph.putIfAbsent(parent, () => {}).add(element);
          }
        }
        _processElement(element);
      }
    }

    if (type is InterfaceType) {
      for (final arg in type.typeArguments) {
        collect(arg, parent);
      }
    } else if (type is FunctionType) {
      collect(type.returnType, parent);
      for (final param in type.formalParameters) {
        collect(param.type, parent);
      }
    } else if (type is RecordType) {
      for (final field in type.positionalFields) {
        collect(field.type, parent);
      }
      for (final field in type.namedFields) {
        collect(field.type, parent);
      }
    }
  }

  void _processElement(Element element) {
    if (visitedElements.contains(element)) return;
    visitedElements.add(element);

    if (element is InterfaceElement) {
      // Methods
      for (final method in element.methods.where((m) => !m.isPrivate)) {
        collect(method.returnType, element);
        for (final param in method.formalParameters) {
          collect(param.type, element);
        }
      }
      // Fields
      for (final field in element.fields.where((f) => !f.isPrivate)) {
        collect(field.type, element);
      }
      // Getters
      for (final getter in element.getters.where((g) => !g.isPrivate)) {
        collect(getter.returnType, element);
      }
      // Setters
      for (final setter in element.setters.where((s) => !s.isPrivate)) {
        for (final param in setter.formalParameters) {
          collect(param.type, element);
        }
      }
      // Constructors
      for (final constructor in
          element.constructors.where((c) => !c.isPrivate)) {
        for (final param in constructor.formalParameters) {
          collect(param.type, element);
        }
      }
      // Supertypes
      for (final superType in element.allSupertypes) {
        collect(superType, element);
      }
    } else if (element is TypeAliasElement) {
      collect(element.aliasedType, element);
    }
  }
}
